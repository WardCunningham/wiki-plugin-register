const gitAuthors = require('grunt-git-authors')

gitAuthors.updatePackageJson({ order: 'date' }, error => {
  if (error) {
    console.log('Error: ', error)
  }
})

gitAuthors.updateAuthors((error, filename) => {
  if (error) {
    console.log('Error: ', error)
  } else {
    console.log(filename, 'updated')
  }
})
