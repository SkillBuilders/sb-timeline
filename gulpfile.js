var gulp = require('gulp');
var zip  = require('gulp-zip');

gulp.task('default',function(){
   return gulp.src(['src/*', '!src/plsql.sql'])
      .pipe(zip('upload.zip'))
      .pipe(gulp.dest('./'));
});