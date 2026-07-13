const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.confirmLoad = functions.https.onRequest(async (req, res) => {
  // Allow CORS for browser requests
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST');
  
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  const loadNumber = req.query.load;
  
  if (!loadNumber) {
    res.redirect('https://yuploaded.com/confirm.html?status=error');
    return;
  }

  try {
    const db = admin.firestore();
    
    // Find load by load number
    const snapshot = await db.collection('loads')
      .where('loadNumber', '==', loadNumber)
      .limit(1)
      .get();

    if (snapshot.empty) {
      res.redirect('https://yuploaded.com/confirm.html?status=notfound&load=' + loadNumber);
      return;
    }

    const loadDoc = snapshot.docs[0];
    const loadData = loadDoc.data();

    // Check if already confirmed
    if (loadData.brokerConfirmed === true) {
      res.redirect('https://yuploaded.com/confirm.html?status=already&load=' + loadNumber);
      return;
    }

    // Mark load as confirmed
    await db.collection('loads').doc(loadDoc.id).update({
      brokerConfirmed: true,
      brokerConfirmedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Increment verified loads on driver profile
    if (loadData.userId) {
      await db.collection('users').doc(loadData.userId).update({
        verifiedLoads: admin.firestore.FieldValue.increment(1),
      });
    }

    // Redirect to success page
    res.redirect('https://yuploaded.com/confirm.html?status=confirmed&load=' + loadNumber);

  } catch (error) {
    console.error('Error confirming load:', error);
    res.redirect('https://yuploaded.com/confirm.html?status=error');
  }
});
