# AL Sandbox Learning Project

This is a standalone, production-ready Microsoft Dynamics 365 Business Central AL Extension Project for learning and testing purposes.

## Project Configuration
- **Publisher**: APSS
- **Extension Name**: al-sandbox-learning
- **ID Range**: 50100 - 50149 (Safe non-conflicting ID range)
- **Target Platform**: 22.0.0.0
- **Runtime**: 11.0

## Features
- **Customer Table Extension**: Adds `APSS External ID` field.
- **Customer Card Page Extension**: Adds the new field to the General FastTab and includes two Promoted Action Buttons (`Test REST API GET` and `Test REST API POST`).
- **REST API Management**: Codeunit containing logic to make HTTP GET and POST requests to an external API (JSONPlaceholder).
- **JSON Array Parser**: Codeunit demonstrating how to parse a JSON array in AL.

---

## Walkthrough Guide for Supervisor Nick

1. Ensure the Business Central environment (Sandbox) is up and running.
2. Open this project in Visual Studio Code.
3. If necessary, download symbols using `AL: Download Symbols` from the Command Palette (`Ctrl+Shift+P`).
4. Press `F5` to compile and publish the extension to your configured environment.
5. Navigate to the **Customers** list in Business Central and open a Customer Card.
6. Verify the **APSS External ID** field is present on the General FastTab.
7. Click the **Test REST API GET** button to verify the HTTP GET functionality. You should see a success message with the fetched title.
8. Click the **Test REST API POST** button to verify the HTTP POST functionality. You should see a success message with the response payload.

---

## Homework Assignment for Interns (Tran Phuc Quy & Dang Nhat Nam)

**Objective**: Extend the existing REST API functionality.

**Instructions**:
1. You will be working on your individual Git branches:
   - `feature/quy-al-rest-api`
   - `feature/nam-al-rest-api`
2. **Task**: Create a new Codeunit or extend the existing `APSS REST API Management` Codeunit to include a function that fetches a list of users (JSON Array) from `https://jsonplaceholder.typicode.com/users`.
3. Use the concepts demonstrated in `APSS Json Array Parser` to parse the response array.
4. Extract the `name` and `email` for each user and display them using a `Message` or insert them into a temporary table to display on a page.
5. Add a new action button on the Customer Card to trigger your new function.
6. Ensure your code compiles without errors and follows AL coding guidelines.
7. Commit and push your changes to your respective branches and create a Pull Request for review by Nick.
