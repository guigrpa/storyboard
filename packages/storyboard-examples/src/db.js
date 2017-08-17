// This module simulates database access
import Promise from 'bluebird';
import _ from 'lodash';
import { mainStory, chalk } from 'storyboard';

const ANIMALS = ['Cow', 'Hummingbird', 'Rhinoceros', 'Capybara', 'Igel', 'Sheep'];

const init = () => mainStory.info('db', 'Initialising database...');

const getItems = ({ story = mainStory } = {}) => {
  story.debug('db', 'Retrieving animals...');
  return Promise.delay(1500)
    .then(() => {
      const numAnimals = 2 + Math.floor(Math.random() * 3);
      const animals = ['Unicorn'].concat(_.sampleSize(ANIMALS, numAnimals));
      story.debug('db', `Animals found: ${chalk.cyan(numAnimals + 1)}`);
      return animals;
    });
};

export default {
  init,
  getItems,
};
