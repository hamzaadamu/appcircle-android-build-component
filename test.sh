set -e
set -x

git clone https://github.com/appcircleio/appcircle-sample-android.git

export AC_MODULE=app
export AC_VARIANTS=debug
export AC_OUTPUT_TYPE=apk

mkdir output-dir
export AC_OUTPUT_DIR=./output-dir
export AC_REPOSITORY_DIR=./appcircle-sample-android
# gradlew path  
export AC_PROJECT_PATH=./
export AC_ENV_FILE_PATH=./env_variables_output.json
  
ruby android_build.rb
cat $AC_ENV_FILE_PATH
