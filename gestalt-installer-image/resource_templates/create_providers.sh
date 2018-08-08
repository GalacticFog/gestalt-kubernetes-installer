

# sendPost - url: http://gestalt-meta.gestalt-system:10131/root/workspaces
# payload: {
#   "name" : "gestalt-system-workspace",
#   "description" : "Gestalt System Workspace"
# }

# 201 - Created
# creating default environment in workspace (3fc0ba03-a499-40f1-94dd-9b7d8d3adca8)...
# sendPost - url: http://gestalt-meta.gestalt-system:10131/root/workspaces/3fc0ba03-a499-40f1-94dd-9b7d8d3adca8/environments
# payload: {
#   "name" : "gestalt-system-environment",
#   "description" : "Gestalt System Environment",
#   "properties" : {
#     "environment_type" : "development"
#   }
# }

# 201 - Created
# creating environment for laser containers...
# sendPost - url: http://gestalt-meta.gestalt-system:10131/root/workspaces/3fc0ba03-a499-40f1-94dd-9b7d8d3adca8/environments
# payload: {
#   "name" : "gestalt-laser-environment",
#   "description" : "Gestalt Laser Environment",
#   "properties" : {
#     "environment_type" : "development"
#   }
# }

fog create resource -f db-provider.json --config config.json

fog create resource -f security-provider.json --config config.json

fog create resource -f kubernetes-provider.json --config config.json

fog create resource -f rabbit-provider.json --config config.json

fog create resource -f logging-provider.json --config config.json

# Link logging provider to CaaS provider

# sendPatch - url: http://gestalt-meta.gestalt-system:10131/root/providers/e79324a6-b8b8-486d-890b-a9e67307380e
# payload: [ {
#   "op" : "replace",
#   "path" : "/properties/linked_providers",
#   "value" : [ {
#     "name" : "logging",
#     "id" : "07b3b6a4-67b7-4626-b341-2665a8a82dc9",
#     "typeId" : "e1782fef-4b7c-4f75-b8b8-6e6e2ecd82b2",
#     "type" : "Gestalt::Configuration::Provider::Logging"
#   } ]
# } ]


# Executors
fog create resource -f js-executor.json --config config.json
fog create resource -f jvm-executor.json --config config.json
fog create resource -f dotnet-executor.json --config config.json
fog create resource -f golang-executor.json --config config.json
fog create resource -f nodejs-executor.json --config config.json
fog create resource -f python-executor.json --config config.json
fog create resource -f ruby-executor.json --config config.json


fog create resource -f laser-provider.json --config config.json

fog create resource -f policy-provider.json --config config.json

fog create resource -f kong-provider.json --config config.json

fog create resource -f gatewaymanager-provider.json --config config.json
