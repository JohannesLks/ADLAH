# ADLAH - Adaptive Deep Learning Anomaly Detection Honeynet

Welcome to the documentation for **ADLAH**, an adaptive honeynet framework designed for **real-time anomaly detection and dynamic threat behavior analysis**.

ADLAH combines:

- **First-flight data capture** (MADCAT sensor)
- **Unsupervised deep learning models** (autoencoder, LSTM, heuristic scoring)
- **Reinforcement learning orchestration** (adaptive pod spawning)
- **Centralized data processing** (ELK stack integration)
- **Scalable high-interaction honeypots** (containerized workloads on Kubernetes)

## Key Features

- **First-flight anomaly detection** using autoencoder + heuristic fusion  
- **Adaptive orchestration**: suspicious sessions trigger containerized high-interaction pods  
- **Centralized analysis**: Elasticsearch + Kibana with secure reverse proxy access  
- **Modular architecture**: sensors, hive (central), and cluster separated  
- **Security-first**: TLS log forwarding, authentication, role-based access, audit-friendly  

## Quickstart

Clone the repository and install the hive (central ELK stack):

```bash
git clone https://github.com/JohannesLks/ADLAH.git
cd ADLAH
```

>Adjust vars in `reinstall.sh` 

```bash
./reinstall.sh
```

## Documentation

* [Installation](install.md) — step-by-step setup for Hive, Sensor, Cluster
* [Usage](usage.md) — working with ADLAH, restart & rotation workflows
* [Architecture](architecture.md) — system design and data flow diagrams
* [Security](security.md) — TLS, authentication, secrets handling
* [Troubleshooting](troubleshooting.md) — common problems and solutions
* [FAQ](faq.md) — frequently asked questions

## Resources

* **GitHub Repository**: [JohannesLks/ADLAH](https://github.com/JohannesLks/ADLAH)
* **License**: GPLv3 — see [LICENSE](https://github.com/JohannesLks/ADLAH/blob/main/LICENSE)


