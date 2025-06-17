flowchart TD
    subgraph DevOps Flow

    A1[Developer Commits]
    A2[Update downloadartifacts.json]
    A3[Build Artifact Image]
    A4[Push to Non-Prod Registry]

    end

    subgraph Lower Envs
    B1[STE]
    B2[CIT]
    end

    subgraph QA Stage
    C1[SIT/QA]
    end

    subgraph Staging
    D1[UAT]
    end

    subgraph Production
    E1[PROD]
    end

    A1 --> A2 --> A3 --> A4
    A4 --> B1
    A4 --> B2
    A4 --> C1
    C1 --> D1
    D1 --> E1

    click A2 "https://your-repo-link.com/downloadartifacts.json" _blank