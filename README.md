# AL Sandbox Learning Project

A Microsoft Dynamics 365 Business Central AL extension created for APSS intern training and the REST API assignment.

## Project Configuration

- **Publisher**: Nick_Nguyen
- **Extension Name**: al-sandbox-learning
- **Configured ID Range**: 50100 - 50149
- **Target Platform**: 22.0.0.0
- **Runtime**: 11.0

## Training Framework

The project includes the REST API and AL extension framework provided for the intern training.

### Customer Table Extension

Adds the following field to the standard Business Central Customer table:

- `APSS External ID`

### Customer Card Page Extension

Extends the standard Customer Card page with:

- `APSS External ID` field in the General FastTab
- `Test REST API GET` promoted action
- `Test REST API POST` promoted action

### REST API Management

Provides HTTP GET and POST examples using JSONPlaceholder.

- GET: fetches a Todo record
- POST: sends customer information to the external API

### JSON Array Parser

Provides JSON array parsing and validation logic in AL.

---

# REST API Assignment

## Objective

Fetch data from an external REST API and independently design the necessary Business Central Tables and Pages to store and display the data.

The current implementation uses the JSONPlaceholder Todo API for training and testing.

## Architecture

```text
External REST API
        |
        v
    HttpClient
        |
        v
REST API Management
        |
        v
JSON Array Parser
        |
        v
Temporary Todo Records
        |
        v
APSS External Todo Table
        |
        v
APSS External Todo List