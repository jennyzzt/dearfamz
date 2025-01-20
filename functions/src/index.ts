import * as functions from "firebase-functions/v1";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {allQuestions} from "./allQuestions";

initializeApp();
const db = getFirestore();

export const healthCheck = functions.https.onRequest((req, res) => {
  res.status(200).send("Health check passed!");
});

export const scheduleWeeklyQuestions = functions.pubsub
  // Runs every Sunday at 00:00 UTC
  .schedule("0 0 * * 0")
  .timeZone("UTC")
  .onRun(async () => { // Removed 'context' as it's unused
    const numQuestions = 8;

    // 1. Shuffle the array of questions
    const shuffled = [...allQuestions].sort(() => 0.5 - Math.random());

    // 2. Pick the first numQuestions from the shuffled array
    const selectedQuestions = shuffled.slice(0, numQuestions);

    // 3. Figure out the date starting tomorrow
    const now = new Date();
    const nextDay = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate() + 1
    );

    // 4. Create a Firestore batch
    const batch = db.batch();

    // 5. For each question, create a document
    selectedQuestions.forEach((questionText, i) => {
      const dayDate = new Date(nextDay);
      dayDate.setDate(nextDay.getDate() + i);

      const docData = {
        question: questionText,
        createdAt: Timestamp.fromDate(dayDate),
      };

      const docRef = db.collection("questions").doc();
      batch.set(docRef, docData);
    });

    // 6. Commit the batch
    await batch.commit();

    console.log(
      `Successfully populated ${numQuestions} random questions for next week!`
    );
    return null;
  });
