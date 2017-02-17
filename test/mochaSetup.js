const sinon = require('sinon');
const chai = require('chai');
const sinonChai = require('sinon-chai');
const { waitUntil } = require('./helpers.coffee');

chai.use(sinonChai);
global.expect = chai.expect;
global.sinon = sinon;
global.waitUntil = waitUntil;
