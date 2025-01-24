<h1 align="center">DearFamz</h1>

<div align="center">

[![Winner Badge](https://img.shields.io/badge/GitHub_Copilot_1--Day_Build_Challenge-Winner-brightgreen?style=for-the-badge)](https://dev.to/devteam/congrats-to-the-github-copilot-1-day-build-challenge-winners-4iok)

</div>

Communicating with my parents has always been a challenge, but I still want to stay connected with them in a way that is not as intrusive to my private life as I would like. Hence, I made **DearFamz**, a mobile application that aims to help family members connect and understand each other better through simple interactions.

DearFamz prompts families at regular intervals (daily or weekly) to share genuine answers to engaging questions. Choose what you wish to share, keep healthy boundaries, and stay connected with your loved ones. This app is heavily inspired by [BeReal](https://bereal.com/).

## Screenshots

Signup Page               | Signup Name Page                | (Home Page) Feed Today               |  (Home Page) Feed All Time
:-------------------------:|:-------------------------:|:-------------------------:|:-------------------------:
![](https://github.com/jennyzzt/dearfamz/blob/main/screenshots/signup_page_filled.png?raw=true)|![](https://github.com/jennyzzt/dearfamz/blob/main/screenshots/signup_name_page_filled.png?raw=true)|![](https://github.com/jennyzzt/dearfamz/blob/main/screenshots/family_feed_today.png?raw=true)|![](https://github.com/jennyzzt/dearfamz/blob/main/screenshots/family_feed_allbuttoday.png?raw=true)|

Connect Today Page         | Edit Family Page         |   Profile Page               |  Profile Edit Page
:-------------------------:|:-------------------------:|:-------------------------:|:-------------------------:
![](https://github.com/jennyzzt/dearfamz/blob/main/screenshots/connecttoday_page_pic.png?raw=true)|![](https://github.com/jennyzzt/dearfamz/blob/main/screenshots/editfamily_page.png?raw=true)|![](https://github.com/jennyzzt/dearfamz/blob/main/screenshots/profile_page.png?raw=true)|![](https://github.com/jennyzzt/dearfamz/blob/main/screenshots/profile_page_edit.png?raw=true)|

## Project Structure
- `lib/` contains all the UI pages
    - `flutter run` to run
- `functions/` contains code to generate questions weekly
    - `firebase emulators:start --only firestore` to emulate Firestore
    - `firebase functions:shell` to test the functions
    - `firebase deploy --only functions` to deploy to production 

## Languages & Tools

[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white&style=for-the-badge)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=white&style=for-the-badge)](https://firebase.google.com)
[![Visual Studio Code](https://img.shields.io/badge/Visual_Studio_Code-0078d7?logo=visual-studio-code&logoColor=white&style=for-the-badge)](https://code.visualstudio.com)
[![GitHub Copilot](https://img.shields.io/badge/GitHub_Copilot-000000?logo=github&logoColor=white&style=for-the-badge)](https://github.com/features/copilot)

## License

[![License](https://img.shields.io/badge/License-Apache_2.0-blue?style=for-the-badge)](https://github.com/jennyzzt/dearfamz/blob/main/LICENSE)
