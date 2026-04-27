# Webhook: [Insert Webhook Name]

## 1. Purpose & Logic
* **Tag / Fulfillment ID:** `[Insert-Tag-Name]` (Matches the "Tag" field in Dialogflow CX fulfillment)
* **System of Record:** (e.g., Salesforce, SAP, On-Prem SQL Server)
* **Description:** (A brief overview of what this webhook does, e.g., "Validates user policy numbers and returns coverage details.")

## 2. Development & Connectivity
* **Runtime:** (e.g., Node.js 20 / Python 3.11)
* **VPC Connector Required:** [Yes/No] (Must be 'Yes' to access internal client IPs via VPN/Interconnect.)
* **Service Account:** `[service-account-name]@[project-id].iam.gserviceaccount.com`
* **Secrets:** List any keys used from GCP Secret Manager (e.g., `API_KEY_SFDC`).

### **Local Environment Setup**
Create a `.env` file in this directory:
PROJECT_ID="your-gcp-project-id"
API_URL="[https://api.client.com/v1](https://api.client.com/v1)"
LOG_LEVEL="debug"

## 3. Request (Input from Dialogflow CX)
The webhook expects the following parameters from the Dialogflow `sessionInfo.parameters` object:

| Parameter Name | Data Type | Description | Required? |
| `account_number` | String | 10-digit user account ID | **Yes** |
| `zip_code` | String | User's billing zip code | **Yes** |

### Sample Payload Snippets
```json
{
  "fulfillmentInfo": {
    "tag": "validate_user"
  },
  "sessionInfo": {
    "parameters": {
      "account_number": "1234567890",
      "zip_code": "90210"
    }
  }
}

The webhook updates the session with the following parameters and optional target page/event.

### Success Response Snippet
```json
{
  "sessionInfo": {
    "parameters": {
      "is_authenticated": "true",
      "user_tier": "gold"
    }
  },
  "fulfillment_response": {
    "messages": [
      {
        "text": {
          "text": [
            "Welcome back! I see you are a Gold member."
          ]
        }
      }
    ]
  }
}
```
## 4. Webhook Error Handling & Resiliency
This project follows a standardized error-handling contract between the Webhook (Cloud Function/Run) and Dialogflow CX to ensure a seamless user experience during system failures.

### Error Classification
| Error Type | Webhook Action | Dialogflow CX Behavior |
| **Validation Error** | Returns `200 OK` with `has_error: true` | Transition to a "Retry" page or play a specific corrective prompt. |
| **System Timeout** | None (Wait for CX to timeout) | Triggers the `sys.webhook.error.timeout` event. |
| **Backend Failure** | Returns `200 OK` with `targetPage` | Redirects user immediately to an **Escalation** or **Maintenance** page. |
| **Auth Failure** | Returns `401/403` status code | Triggers `sys.webhook.error.adverse-http-status`. |

---

### Standard Error Payload
When a backend API fails, the webhook should catch the error and return a "Safe" response to Dialogflow to control the conversation flow.

**Response for Backend Failures:**
```json


