view = (require './src/lazor') './example/views', './example/temp'

model = 
	terms: 'about & stuff'
	searchResults: [
		{ url: '/about', name: 'About Us', summary: '<p>The <em>about</em> us page!</p>' }
		{ url: '/', name: 'Home Page', summary: '<p>Find out <em>about</em> our homepage!</p>' }
	]

result = view '~/sample.lz.html' model

console.log result
