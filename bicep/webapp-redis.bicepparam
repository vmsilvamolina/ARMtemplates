using './webapp-redis.bicep'

param appName = 'myapp'
param appServicePlanSku = 'S1'
param redisSku = 'Standard'
param redisCapacity = 1
param logAnalyticsWorkspaceId = ''
