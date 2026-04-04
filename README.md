# ADLAH  
**Adaptive Multi-Layered Honeynet Architecture for Threat Behavior Analysis via Machine Learning**

> ADLAH is a research-driven honeynet architecture that combines low-interaction sensing, telemetry aggregation, anomaly scoring, and selective escalation to deeper analysis environments.  
> The project is designed to move beyond static honeypot deployments by prioritizing promising sessions and allocating high-interaction resources only when justified by observed behavior.

## Abstract

ADLAH is a multi-layered security research architecture for observing and analyzing attacker behavior through adaptive deception.  
The system combines broad low-interaction sensing, centralized telemetry collection, machine-learning-based anomaly scoring, and selective escalation to higher-interaction environments.  
Instead of treating all sessions equally, ADLAH is designed to identify promising or unusual activity early and to allocate deeper inspection resources only when they are likely to yield additional insight.  
The architecture is built around a sensor/hive model with MADCAT-inspired network-facing collection, ELK-based telemetry processing, and a research pipeline for anomaly detection and orchestration.  
Its long-term goal is to support structured threat observation, attack-chain analysis, and efficient resource usage in large-scale honeynet environments.  
This repository contains the deployment foundation, architecture documentation, and research artifact scaffolding accompanying the ADLAH research direction.

## Research Question

How can low-interaction, network-wide sensing be combined with anomaly scoring and selective escalation to higher-interaction environments in order to capture attacker behavior more efficiently and more meaningfully than static honeynet deployments?

## Why ADLAH?

Traditional honeynet and honeypot deployments often face a trade-off between breadth and depth:

- low-interaction systems scale well but provide limited behavioral detail,
- high-interaction systems provide richer insight but are costly to operate and expose.

ADLAH addresses this trade-off through adaptive escalation:
it observes broadly, scores early, and escalates selectively.

## Core Idea

The architecture follows a layered decision process:

1. **Low-interaction observation** captures broad attacker activity with minimal resource cost.
2. **Telemetry aggregation and preprocessing** normalize and centralize events.
3. **Anomaly scoring and heuristics** identify sessions that deserve further attention.
4. **Selective escalation** activates deeper interaction or analysis resources only for promising cases.
5. **Cross-stage feedback** improves orchestration and supports structured threat analysis.

## System Overview

ADLAH is organized around two main roles:

- **Sensor**  
  Network-facing low-interaction capture and telemetry forwarding.

- **Hive**  
  Centralized ingestion, storage, visualization, analysis, and orchestration.

The architecture is intended to integrate:

- MADCAT-inspired first-flight or low-interaction collection,
- ELK-based telemetry ingestion and analysis,
- anomaly detection components,
- orchestration logic for selective escalation,
- optional reinforcement-learning-driven resource decisions.

## Architecture

```mermaid
flowchart TD
    A[Internet / Attacker Traffic] --> B[Sensor Node]
    B --> B1[MADCAT / Low-Interaction Collection]
    B1 --> B2[Session & Event Logs]
    B2 --> C[Secure Telemetry Forwarding]

    C --> D[Hive]
    D --> D1[Logstash / Ingestion]
    D1 --> D2[Elasticsearch / Storage]
    D2 --> D3[Kibana / Analysis]

    D2 --> E[Feature Extraction]
    E --> F[Anomaly Detection / Heuristic Scoring]
    F --> G[Fusion / Decision Layer]

    G -->|Escalate| H[Dispatcher]
    H --> I[High-Interaction Container / Pod]
    I --> J[Deeper Session Analysis]

    J --> K[Reward / Feedback]
    K --> L[RL Agent / Policy Logic]
    L --> H

    G -->|No Escalation| M[Retain as Low-Interaction Observation]
````

## Repository Status

ADLAH is an **active research artifact**.

This public repository currently focuses on:

* deployment and infrastructure scaffolding,
* architecture documentation,
* integration logic for sensor/hive operation,
* research framing and artifact packaging.

The following parts are at different maturity levels and should be interpreted accordingly.

| Component                            | Status                  |
| ------------------------------------ | ----------------------- |
| Sensor/Hive deployment foundation    | Available               |
| ELK-based telemetry pipeline         | Available / evolving    |
| MADCAT-based collection integration  | Available / evolving    |
| Architecture documentation           | Available               |
| First-stage anomaly scoring pipeline | Prototype / in progress |
| Selective escalation logic           | Prototype / in progress |
| RL-based orchestration               | Experimental / planned  |
| Full benchmark evaluation            | In progress             |
| Public sanitized dataset artifact    | Planned / partial       |
| Reproducibility packaging            | In progress             |

## Key Contributions

This repository documents and incrementally implements the following ideas:

* a **multi-layered honeynet architecture** rather than a single static honeypot setup,
* **adaptive escalation** from broad low-interaction sensing to deeper analysis,
* a **sensor/hive deployment model** for scalable telemetry collection,
* integration of **machine-learning-assisted anomaly scoring** into deception workflows,
* a path toward **resource-aware orchestration** using policy-based or RL-based decision logic,
* a research-oriented structure for future work on **attack-chain extraction** and attacker behavior analysis.

## Repository Structure

```text
ADLAH/
├── docker/                  # container images and compose definitions
├── config/                  # configuration files
├── docs/                    # architecture docs, figures, artifact notes
├── scripts/                 # helper and deployment scripts
├── artifacts/               # artifact metadata, sample inputs, evaluation notes
├── examples/                # example configs, sample runs, demo inputs
├── install.sh               # installation entry point
├── deploy.sh                # deployment helper
├── CHANGELOG.md
├── CITATION.cff
├── LICENSE
└── README.md
```

## Getting Started

### Prerequisites

ADLAH is currently intended for Linux-based environments with container support.

Typical requirements include:

* Docker and Docker Compose
* Linux host(s) for sensor and/or hive deployment
* network access appropriate for telemetry forwarding
* sufficient storage for ELK data
* optional Kubernetes environment for later-stage escalation experiments

### Minimal Setup

A minimal deployment typically consists of:

* **one Hive node** for ingestion, storage, and visualization,
* **one Sensor node** for low-interaction collection and log forwarding.

Example workflow:

1. Prepare the target environment.
2. Review and adjust environment-specific configuration.
3. Run the installation workflow.
4. Deploy the selected role (`hive` or `sensor`).
5. Verify ingestion, storage, and dashboard availability.

> The exact commands depend on your current installation workflow and should be adapted to the state of the project.

## Reproducibility

This repository is intended to evolve into a reproducible research artifact.

At the current stage, reproducibility includes:

* infrastructure and deployment logic for the sensor/hive architecture,
* documented configuration structure,
* versioned code and architecture documentation,
* sample artifacts and environment notes.

Planned reproducibility additions include:

* sanitized example telemetry,
* fixed configuration snapshots,
* scripted experiment setup,
* baseline evaluation recipes,
* versioned experiment outputs.

## Evaluation Status

ADLAH is an active research project, not a finished benchmark package.

Current evaluation-related work focuses on:

* validating the deployment architecture,
* verifying telemetry flow from sensor to hive,
* testing the feasibility of staged analysis,
* preparing feature extraction and anomaly detection pipelines,
* structuring future experiments for session prioritization and selective escalation.

A full experimental section with datasets, metrics, and benchmark results is being prepared separately and should not be inferred as complete from this repository alone.

## Datasets and Artifacts

Due to size, privacy, and operational constraints, large-scale research datasets are **not bundled directly** with this repository.

This repository is intended to provide:

* dataset documentation,
* schema descriptions,
* sample or sanitized example events,
* artifact notes for reproducing
