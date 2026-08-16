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
- **Customer Card Page Extension**: Adds the new field to the General FastTab and provides actions for the sample GET/POST calls and the External Users list.
- **REST API Management**: Codeunit containing logic to make HTTP GET and POST requests to an external API (JSONPlaceholder).
- **JSON Array Parser**: Codeunit demonstrating how to parse a JSON array in AL.
- **External User Synchronization**: Fetches users from JSONPlaceholder, validates the full JSON payload, and atomically synchronizes typed user records.
- **External Users Pages**: Read-only list and detail card for inspecting contact, company, address, coordinate, and synchronization data.

---

## Interns Workspace
- **Will** (Branch: `feature/will-al-rest-api`)
- **Daniel** (Branch: `feature/daniel-al-rest-api`)

## External User Walkthrough

1. Publish the extension and allow outbound HTTP requests for the extension in **Extension Management**.
2. Assign the **APSS REST API** permission set to the test user.
3. Search for **External Users**, or open a Customer Card and choose **External Users**.
4. Choose **Clear All Users** to reset previously synchronized demo data when necessary.
5. Choose **Synchronize**. The page displays records fetched from `https://jsonplaceholder.typicode.com/users` and reports inserted, updated, and deleted counts.
6. Select a user and choose **Open Details** to review the grouped contact, address, coordinate, and synchronization fields.

The synchronization parses the complete response into a temporary table before changing stored data. Invalid JSON, missing required values, duplicate IDs, oversized values, transport failures, and non-success HTTP status codes raise actionable errors without partially replacing the existing user list.
