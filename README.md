
- roles are split out of agents
- agent is in role which uses set of skills to orchestrate set of worker subagents
- tools are provided by nix only, agents work on clone of repo in fsh in tmp
- strict harness setup - cannot run somethig fails whole pipeline; no steps arbitrary disabled and not run to end
- can access folders speicifed in fsh of nix shell, and only use tokens(and dotconfigs tokens) added explicitly
- only bash and python are generated orchestrator, unlses some niche 3rd party thing is not python nor shell covered