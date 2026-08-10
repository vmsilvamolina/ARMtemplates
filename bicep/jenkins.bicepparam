using './jenkins.bicep'

param vmName = 'vm-jenkins'
param vmSize = 'Standard_B2s'
param adminUsername = 'jenkinsadmin'
// Reemplazar por la clave pública real. Nunca commitear la privada.
param adminSshPublicKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC-REEMPLAZAR'
// Nunca 0.0.0.0/0. Poner la IP pública propia con /32.
param allowedSshSourceCidr = '203.0.113.10/32'
param logAnalyticsWorkspaceId = ''
