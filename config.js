module.exports = {
  platform: 'local',
  enabledManagers: ['gitlabci'],
  packageRules: [
    {
      matchManagers: ['gitlabci'],
      matchDatasources: ['docker'],
      matchUpdateTypes: ['pinDigest', 'digest'],
      enabled: true,
      pinDigests: true,
      minimumReleaseAge: '14 days',
      minimumReleaseAgeBehaviour: 'timestamp-required'
    },
  ],
};
