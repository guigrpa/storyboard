import globby from 'globby';

const listPackages = () => globby('packages/*');

export default listPackages;
