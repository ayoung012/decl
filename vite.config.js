import imba from 'imba/plugin';
import { defineConfig } from 'vite';

export default defineConfig({
	base: '/imba',
	plugins: [imba()],
});
