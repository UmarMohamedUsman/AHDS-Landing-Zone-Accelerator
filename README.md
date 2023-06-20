# AHDS Reference Architecture

This repo is for building secure landing zone accelerator for Azure Health Data Services (AHDS) and to integrate with various Azure Services.

![ahds reference architecture](./media/AHDS%20Reference%20Architecture.png)

### Introduction

Security is a paramount concern for Healthcare customers as they deal with Protected Health Information. Goal of this hackathon project is to come up with secure landing zone for deploying Azure Health Data Services (AHDS).

Currently we've no reference architecture in Azure Architecture Center for deploying AHDS and integrating with various Azure Services in a typical enterprise environment with security in mind. This has been a huge pain point for customers looking to deploy AHDS following Microsoft recommended best practices and continue to hinder AHDS adoption.

### Use cases

Once we have the reference architecture deployed successfully, we will be able to receive FHIR messages (individually/bulk) securely over a TLS connection through Application Gateway and successfully persist in AHDS. Then FHIR Sync Agent reads data from AHDS, convert to Parquet files and writes it to Azure Data Lake Gen2. Azure Synapse can connect to Data Lake to query and analyze FHIR data.

- We can extend this to receive medical device/wearable data and persist in MedTech service and give insights to Doctors/Nurses (using Synapse)
- We can extend this to ingest non FHIR data (HL7, C-CDA) and convert to FHIR and persist

### Details

- Typical Hub & Spoke network architecture to align with Cloud Adoption Framework Landing Zone design principles
- Data hitting Application Gateway should be in FHIR format. Ingestion pipeline to transform HL7 v2 to FHIR or C-CDA to FHIR will be added to this architecture eventually
- Azure Health Data Services with private endpoint to ensure no publicly accessible endpoint
- Azure Application Gateway to securely ingest bulk data or individual FHIR objects
- Clients can securely access Patient or Provider data over TLS using Application Gateway endpoints
- Optionally add Web Application Firewall to Application Gateway, but there are known limitations with this as WAF doesn’t recognize FHIR objects. We may have to come up with WAF ruleset that works with FHIR.
- Azure Key Vault with private endpoint to securely store client secrets, Application Gateway certificates, etc.
- Application Gateway securely loads bulk data into storage account.
- Azure Storage Account with private endpoint for securely bulk loading FHIR data.
- Using VNet integration FHIR loader Function directly listen/pulls bulk data directly from blob storage behind private endpoint and loads it in to AHDS.
- Azure Container Registry with private endpoint for securely storing customized Liquid templates
- Azure Active Directory for FHIR API Authentication and RBAC
- Application Insights for Monitoring
- FHIR Synapse sync agent extracts data from AHDS converts to hierarchical Parquet files, and writes it to Azure Data Lake
- Azure Synapse uses serverless SQL/Spark pool to connect to Data Lake to query and analyze FHIR data
- Hub VNet will contain jumpbox VM along with Azure Bastion Host to securely access FHIR service configuration, testing FHIR service endpoints without Application Gateway, bulk loading FHIR data manually through Azure storage with private endpoint, etc.
- If on-premises network connectivity established over Site-to-Site VPN or Express Route then on-premises users/services can directly access AHDS over this connection, rather than connecting through Application Gateway.
- Enable Microsoft Defender for Cloud as well as HIPAA & HITRUST compliances. This will ensure customer deployment adhere to Microsoft Security Benchmark and Healthcare compliance requirements.

### Getting Started

- Clone the repo

  ```sh
  git clone https://github.com/UmarMohamedUsman/AHDS-Landing-Zone-Accelerator
  ```

- Open this folder in Visual Studio Code to review all the "parameters-\*" files under three folders (01-Network-Hub, 02-Network-LZ & 03-AHDS) to review the values and change as needed per your environment.
  - For example under 01-Network-Hub folder you have following three "parameters-\*" files, make sure to review all three of them. - parameters-deploy-vm.json - parameters-main.json - parameters-updateUDR.json
    <br/>

<!-- - Navigate to the following folder

  ```sh
  cd AHDS-Landing-Zone-Accelerator/Scenarios/Baseline/bicep
  ``` -->

- Using Visual Studio Code review and change "deployment.azcli" file under "Scenarios/Baseline/bicep" folder. For example, change Names and Azure Region as needed.
  <br/>

- Execute the script in "deployment.azcli"

### Testing

Once the reference architecture successfully deployed you can test the solution using Postman.

- Visit another page and follow the instructions for setting up Postman
- Make API calls to test FHIR service using Postman

To begin, CTRL+click (Windows or Linux) or CMD+click (Mac) on the link below to open a Postman tutorial in a new browser tab.

[Postman Setup Tutorial](https://github.com/microsoft/azure-health-data-services-workshop/blob/main/resources/docs/Postman_FHIR_service_README.md)
