const admin = require('firebase-admin');
const {onDocumentCreated} = require('firebase-functions/v2/firestore');
const {logger} = require('firebase-functions');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Haversine distance in KM.
function distanceKm(lat1, lon1, lat2, lon2) {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const earthKm = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthKm * c;
}

function inScope(taameem, user) {
  if (taameem.allKingdom === true) return true;

  const centerLat = Number(taameem.scopeCenterLat ?? taameem.latitude);
  const centerLng = Number(taameem.scopeCenterLng ?? taameem.longitude);
  const radiusKm = Math.max(1, Number(taameem.radiusKm ?? 10));

  const userLat = Number(user.defaultLocationLat ?? user.lastKnownLat);
  const userLng = Number(user.defaultLocationLng ?? user.lastKnownLng);

  if (!Number.isFinite(centerLat) || !Number.isFinite(centerLng)) return false;
  if (!Number.isFinite(userLat) || !Number.isFinite(userLng)) return false;

  return distanceKm(centerLat, centerLng, userLat, userLng) <= radiusKm;
}

function normalizeTokens(rawTokens) {
  if (Array.isArray(rawTokens)) {
    return rawTokens.filter((t) => typeof t === 'string' && t.trim().length > 0);
  }
  if (typeof rawTokens === 'string' && rawTokens.trim().length > 0) {
    return [rawTokens];
  }
  return [];
}

exports.notifyUsersByScope = onDocumentCreated(
  {
    document: 'taameems/{taameemId}',
    region: 'me-central1',
    memory: '512MiB',
    timeoutSeconds: 120,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const taameem = snap.data();
    if (!taameem || taameem.status !== 'active') return;

    logger.info('notifyUsersByScope start', {
      taameemId: snap.id,
      radiusKm: taameem.radiusKm,
      allKingdom: taameem.allKingdom,
      city: taameem.city,
    });

    const usersSnapshot = await db.collection('users').get();
    const batchTokens = [];

    for (const userDoc of usersSnapshot.docs) {
      const user = userDoc.data() || {};
      const tokens = normalizeTokens(user.fcmTokens || user.fcmToken);
      if (tokens.length === 0) continue;

      if (!inScope(taameem, user)) continue;
      batchTokens.push(...tokens);
    }

    const uniqueTokens = Array.from(new Set(batchTokens));
    if (uniqueTokens.length === 0) {
      logger.info('No users in scope for taameem', {taameemId: snap.id});
      return;
    }

    const payload = {
      notification: {
        title: taameem.title || 'تعميم جديد',
        body: taameem.description || 'تم نشر تعميم جديد في نطاقك',
      },
      data: {
        taameemId: snap.id,
        type: String(taameem.type || ''),
        city: String(taameem.city || ''),
      },
      android: {
        priority: 'high',
      },
    };

    const chunkSize = 500;
    let totalSent = 0;

    for (let i = 0; i < uniqueTokens.length; i += chunkSize) {
      const chunk = uniqueTokens.slice(i, i + chunkSize);
      const resp = await messaging.sendEachForMulticast({
        tokens: chunk,
        ...payload,
      });

      totalSent += resp.successCount;

      // Remove invalid tokens from users collection lazily (best effort).
      const invalidTokens = [];
      resp.responses.forEach((r, idx) => {
        if (!r.success) {
          const code = r.error?.code || '';
          if (
            code.includes('registration-token-not-registered') ||
            code.includes('invalid-argument')
          ) {
            invalidTokens.push(chunk[idx]);
          }
        }
      });

      if (invalidTokens.length > 0) {
        const removeOps = usersSnapshot.docs.map((u) => {
          const data = u.data() || {};
          const tokens = normalizeTokens(data.fcmTokens || data.fcmToken);
          const keep = tokens.filter((t) => !invalidTokens.includes(t));
          if (keep.length === tokens.length) return null;
          return u.ref.set({fcmTokens: keep}, {merge: true});
        }).filter(Boolean);

        await Promise.allSettled(removeOps);
      }
    }

    logger.info('notifyUsersByScope done', {
      taameemId: snap.id,
      tokenCount: uniqueTokens.length,
      sent: totalSent,
    });
  }
);
