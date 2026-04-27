# Google Template


# Project: [Project Name] 

## 1. Executive Summary & Client Info
* **Client:** [Client Name]
* **Project Status:** [Discovery | MVP | Production]
* **Primary Objective:** (e.g., Automating Tier 1 support via LLM Playbooks.)
* **Stakeholders:** [Name/Role]
* **Brand Voice/Tone:** [e.g., Professional, empathetic, concise.]


## 2. Dialogflow CX Components
| Component Type | Name/ID | Role / Description |
| :--- | :--- | :--- |
| **Flows** | `Default Start Flow` | Main logic gates for deterministic routing. |
| **Playbooks** | `Advisor_Bot` | LLM-driven reasoning for complex product queries. |
| **Generators** | `Summarizer` | Summarizes the transcript before agent handoff. |
| **Data Stores** | `KB_Vertex_AI` | RAG source for unstructured PDF manuals. |
| **Intents** | `intent.billing.pay` | Key NLU triggers for the billing flow. |


## 3. Agent Studio CX (Generative AI)
This project utilizes the latest **Agent Studio** features for Generative AI and Reasoning.

| Feature | Resource Name | Description / Use Case |
| **Generative Agent** | `Retail_Support_Agent` | The main AI agent defined in Agent Studio. |
| **Grounding** | `DataStore_Grounding` | Ensures responses are grounded in the enterprise knowledge base. |
| **Agent Tools** | `API_Tool_Suite` | Set of extensions (Search, Webhooks, Functions) available to the AI. |

### **Agent Configurations**
* **Model Selection:** (e.g., Gemini 1.5 Flash / Pro)
* **System Instructions:** > *Paste the high-level system prompt from Agent Studio here.*
* **Safety Settings:** [Standard | Strict] – Configured to block Hateful or Harassing content.
* **Grounding Threshold:** [e.g., 0.7] – Confidence score required for the AI to cite a source.

### **Prompt Versions**
* **Active Version:** `v2.4-stable`
* **Draft Version:** `v2.5-beta-testing`
* **Testing Logs:** Found in GCP Console under **Agent Studio > Monitor**.


## 4. Use Cases
* **Primary Use Case:** [e.g., Billing Inquiries] - Handles invoice explanation and payment.
* **Secondary Use Case:** [e.g., Appointment Scheduling] - Integrates with CRM to book slots.
* **Edge Case Handling:** [e.g., Fraud Reporting] - Detects high-risk keywords for immediate escalation.


## 5. Networking & Connectivity (VPC / VPN)
* **VPC Name:** `[VPC-Name]` (e.g., `cx-production-vpc`)
* **Subnet:** `[Subnet-Range]` (e.g., `10.1.0.0/24`)
* **Connectivity Method:** [Cloud VPN | Cloud Interconnect] to `[Client Gateway IP]`.
* **VPC Service Controls:** [Enabled/Disabled] – Status of the security perimeter.
* **Serverless VPC Access:** `[Connector-Name]` – Required for Webhooks to reach internal IPs.


## 6. GCP Infrastructure & Security
| Service | Resource Name / ID | Purpose |
| :--- | :--- | :--- |
| **Project ID** | `[GCP-Project-ID]` | Master project for the agent. |
| **DLP API** | `[Template-Name]` | PII redaction for session logs and BigQuery. |
| **BigQuery** | `[Dataset].[Table]` | Storage for CX Insights & Custom Reporting. |
| **Cloud Storage**| `gs://[bucket-name]` | Source for RAG data & agent backups. |
| **Artifact Reg.**| `webhook-images` | Container storage for Webhook logic. |


## 7. Escalation & Handoff
* **Triggers:** User request or 3 consecutive Fallbacks.
* **Platform Mapping:** [e.g., Genesys Cloud CX via SIP Trunking]
* **Payload Structure:**
{
  "handoff_metadata": {
    "reason": "$session.params.escalation_reason",
    "summary": "$session.params.interaction_summary",
    "context": { "account_id": "$session.params.account_id" }
  },
  "telephony": { "transfer_target": "+18005550199" }

}


## 8. CI/CD & Terraform

* **Terraform:** Located in `/terraform`. Manages VPC connectors, Data Stores, and Agent state.
* **Pipelines (GitHub Actions):**
    * **Webhook Deploy:** Pushes code to Cloud Run on merge to `main`.
    * **Agent Validation:** Runs CX "Validation" API on every Pull Request to check for overlaps/errors.
    * **Regression Test:** Daily scheduled execution of CX Test Cases to ensure NLU accuracy.


## 9. Challenges & Lessons Learned

### Technical Challenges
* **VPN Latency:** Experienced ~500ms delays when webhooks called on-prem APIs.
    * *Resolution:* Implemented a caching layer in the webhook for non-sensitive data.
* **Intent Overlap:** High confusion between `billing.pay` and `billing.status`.
    * *Resolution:* Tightened training phrases and utilized "Intent Power" settings in the CX console.

### Integration & Constraints
* **SIP Header Limits:** The client IVR had a 1024-character limit for metadata.
    * *Resolution:* Stripped the payload to only essential session IDs and a short code.
* **Maintenance Windows:** Client APIs are down Sundays from 2 AM–4 AM.
    * *Resolution:* Added a conditional path in the Dialogflow flow to play a "System Maintenance" message during these hours.

## 10. Webhook Compute (Cloud Run & Functions)

This project utilizes Google Cloud's serverless compute to host webhook logic. Depending on the complexity, services are deployed as either **Cloud Run services** or **Cloud Run Functions**.

---

### 1. Deployment Overview

| Feature | Cloud Run (Containers) | Cloud Run Functions |
| :--- | :--- | :--- |
| **Use Case** | Complex logic, multi-endpoint APIs. | Lightweight, single-purpose logic. |
| **Scaling** | Scales to zero; handles concurrency. | Scales to zero; 1 request per instance. |
| **Artifact** | Docker Image (Artifact Registry). | Source Code (Zip/Git). |
| **Timeout** | Up to 60 mins (CX limited to 30s). | Up to 9 mins (CX limited to 30s). |

---

### 2. Service Configuration

* **Region:** `us-central1` (Keep in the same region as the CX Agent to minimize latency).
* **Ingress Settings:** *Internal and Cloud Load Balancing* (Recommended for security) or *Allow All* (If testing publicly).
* **Authentication:** Ensure `cloud-run-invoker` permissions are granted to the Dialogflow Service Agent.
* **Concurrency:** For Cloud Run, set concurrency to **80** to optimize cost and performance under load.

---

### 3. Serverless VPC Access

To allow Cloud Run or Functions to access on-prem databases via VPN/Interconnect, a **VPC Connector** is required.

* **Connector Name:** `projects/[ID]/locations/[LOC]/connectors/[NAME]`
* **Egress Settings:** * **Private ranges only:** Routes only internal traffic through the VPN.
    * **All traffic:** Routes all outgoing requests through the VPC (Recommended if using a static NAT IP).

---

### 4. Deployment Commands (gcloud CLI)

**For Cloud Run Functions:**

```bash
gcloud functions deploy [FUNCTION_NAME] \
  --gen2 \
  --runtime=[RUNTIME] \
  --trigger-http \
  --vpc-connector=[CONNECTOR_NAME] \
  --egress-settings=all-traffic \
  --set-env-vars PROJECT_ID=[ID]
