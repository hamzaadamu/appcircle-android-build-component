require 'yaml'
require 'open3'
require 'fileutils'
require 'pathname'

def get_env_variable(key)
	return (ENV[key] == nil || ENV[key] == "") ? nil : ENV[key]
end

ac_module = get_env_variable("AC_MODULE") || abort('Missing module.')
ac_variants = get_env_variable("AC_VARIANTS") || abort('Missing variants.')
ac_output_type = get_env_variable("AC_OUTPUT_TYPE") || abort('Missing output type.')
ac_repo_path = get_env_variable("AC_REPOSITORY_DIR") || abort('Missing repo path.')
ac_output_folder = get_env_variable("AC_OUTPUT_DIR") || abort('Missing output folder.')

ac_gradle_params = get_env_variable("AC_GRADLE_BUILD_PARAMS") || ""
ac_project_path = get_env_variable("AC_PROJECT_PATH") || "."

def get_gradle_task(output_type, variants, module_name)
    gradle_task = ""
    build_type = (output_type == "aab") ? "bundle" : "assemble"
    variants.split(',').each { 
        | variant | gradle_task << " #{module_name}:#{build_type}#{variant}"
    }
    return gradle_task
end

def runCommand(command)
    puts "@[command] #{command}"
    status = nil
    stdout_str = nil
    stderr_str = nil

    Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
        stdout.each_line do |line|
            puts line
        end
        stdout_str = stdout.read
        stderr_str = stderr.read
        status = wait_thr.value
    end

    unless status.success?
        puts stderr_str
        raise stderr_str
    end
    return stdout_str
end

gradlew_folder_path = ""
if Pathname.new("#{ac_project_path}").absolute?
    gradlew_folder_path = ac_project_path
else
    gradlew_folder_path = File.expand_path(File.join(ac_repo_path, ac_project_path))
end

gradle_task = get_gradle_task(ac_output_type, ac_variants, ac_module)

build_output_folder = File.join(gradlew_folder_path,"#{ac_module}/build/outputs")
unless ac_gradle_params.strip.empty?
    gradle_task = "#{gradle_task} #{ac_gradle_params}"
end

command = "cd #{gradlew_folder_path} && chmod +x ./gradlew && ./gradlew clean #{gradle_task}"
runCommand(command)

puts "Filtering artifacts: #{build_output_folder}/**/*.apk, #{build_output_folder}/**/*.aab"

apks = Dir.glob("#{build_output_folder}/**/*.apk")
aabs = Dir.glob("#{build_output_folder}/**/*.aab")

FileUtils.cp apks, "#{ac_output_folder}"
FileUtils.cp aabs, "#{ac_output_folder}"

apks = Dir.glob("#{ac_output_folder}/**/*.apk").join(",")
aabs = Dir.glob("#{ac_output_folder}/**/*.aab").join(",")

puts "Exporting AC_APK_PATH=#{apks}"
puts "Exporting AC_AAB_PATH=#{aabs}"

open(ENV['AC_ENV_FILE_PATH'], 'a') { |f|
    f.puts "AC_APK_PATH=#{apks}"
    f.puts "AC_AAB_PATH=#{aabs}"
}

exit 0
