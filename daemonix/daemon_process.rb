# This is a module to launch daemons
module Daemonix
  require 'daemons'
  require 'json'
  require 'fileutils'
  # describing class Daemonprocess
  # Call the start method and stop method with params :
  #  process_name
  #  pid_directory path (optional) : if not given will use or create 'pid_dir'
  #   in current module directory
  #  a block or proc or lambda has to be given to be launch in daemon
  #  it returns the pid number and the pid_file path that have to be stored
  #  in order to retrive and stop the process
  # ex for starting daemon : DaemonService::DaemonProcess.start('proc',
  #   '/home/michael.ramassamy/Bureau/Documents pro/code/create_file_app/
  #    daemon_service') { DaemonService::DaemonProcess.start_action }
  # ex for stopping daemon : DaemonService::DaemonProcess.stop('proc',
  #   '/home/michael.ramassamy/Bureau/Documents pro/code/
  #    create_file_app/daemon_service')
  #  There are 2 wayds to stop process: with process_name and with process_pid
  #  USe one of these methods : stop  or stop_process
  # Note : to see process ruby running, type in terminal : pgrep ruby
  class DaemonProcess
    class << self
      PID_DIR = File.join(__dir__, 'pid_dir')
      PIDS_FILE = File.join(__dir__, 'pids_list.json')

      def start(args = {}, &action)
        # initialize arguments and directory
        params = {}
        args[:process_name] ||= 'daemonprocess'
        params[:app_name] = args[:process_name] + '_' + Time.now.to_i.to_s
        params[:dir] = args[:pid_directory] || PID_DIR
        check_or_create_directory(params[:dir])
        action ||= proc { action_to_daemon }
        # validate_or_change_process_name(process_name)
        # launch daemon and get pid
        process_infos = launch(params, action)
        # cleanup process list if processes have ended
        cleanup_pids_list
        #  return process infos to be stored by the caller
        puts process_infos
        process_infos
      end

      def stop(process_name, pid_directory = PID_DIR)
        cleanup_pids_list
        pid_directory = PID_DIR unless File.exist?(pid_directory)
        pid_file = File.join(pid_directory, "#{process_name}.pid")
        if File.exist?(pid_file)
          process_pid = File.read(pid_file).to_i
          puts "--- Stopping process #{process_pid} and deleting #{pid_file}"
          terminate(process_pid, pid_file)
          after_stop_action
        else
          puts '---No pid found for this process name---'
        end
      end

      #  Using stop_process to end a process will not delete the pid_file
      def stop_process(process_pid)
        terminate(process_pid)
        cleanup_pids_list
      end

      def stop_all
        cleanup_pids_list
        processes = JSON.parse(File.read('pids_list.json'))
        processes.each do |process|
          stop(process['process_name'], process['pid_dir'])
        end
        # TODO: cleanup_pid_dir in case there are some orphan files
      end

      # use hash for args : pid: xxx   or pid_file: 'xxxx'
      def running?(arg)
        pid = get_pid(arg)
        return '--- No pid found for checking process' unless pid
        begin
          Process.getpgid(pid)
          true
        rescue Errno::ESRCH
          false
        end
      end

      def index
        cleanup_pids_list
        list_of_processes = File.read(PIDS_FILE)
        puts list_of_processes
        list_of_processes
      end

      private

      def get_pid(arg)
        if arg[:pid_file] && File.exist?(arg[:pid_file])
          File.read(arg[:pid_file]).to_i
        else
          arg[:pid] ? arg[:pid] : nil
        end
      end

      def check_or_create_directory(pid_directory)
        begin
          FileUtils.mkdir_p(pid_directory) unless File.exist?(pid_directory)
        rescue Errno::ENOENT => e
          puts e.message
          puts e.backtrace.inspect
          pid_directory = PID_DIR
        end
        pid_directory
      end

      def launch(options, action)
        # add line below if you need to see a log output of the process
        #  but you have to delete manually the file  app_name.ouput
        # options[:log_output] = true
        daemon = Daemons.call(options) do
          action.call
        end
        puts '---Daemon has started---'
        store_and_return_daemon_infos(daemon)
      end

      def store_and_return_daemon_infos(daemon)
        create_pids_file_json_if_absent
        new_entry = { process_name: daemon.group.app_name,
                      pid: daemon.pid.pid,
                      pid_dir: daemon.pidfile_dir }
        json_content = File.read(PIDS_FILE)
        File.open(PIDS_FILE, 'w') do |f|
          f.puts JSON.pretty_generate(JSON.parse(json_content) << new_entry)
        end
        new_entry
      end

      def create_pids_file_json_if_absent
        # create json file with empty array if file does not exist
        return unless File.exist?(PIDS_FILE)
        File.open(PIDS_FILE, 'w+') { |f| f.puts JSON.pretty_generate([]) }
      end

      def terminate(process_pid, pid_file = nil)
        begin
          Process.kill 9, process_pid
          puts '---Stopped process---'
        rescue Errno::ESRCH => e
          puts e.message + '   ---   ' + e.backtrace.inspect
          puts '---Process does not exist---'
        end
        if pid_file
          File.delete pid_file
          puts '---Deleted pid_file---'
        end
        cleanup_pids_list(process_pid)
      end

      def cleanup_pids_list(process_pid = nil)
        puts '---Update pids_list.json'
        content = JSON.parse(File.read(PIDS_FILE))
        content.delete_if { |process| running?(pid: process['pid']) == false }
        if process_pid
          content.delete_if { |process| process['pid'] == process_pid }
        end
        File.open(PIDS_FILE, 'w') do |f|
          f.write JSON.pretty_generate(content)
        end
      end

      def action_to_daemon
        # you can add default action
      end

      def after_stop_action
        # you can add default callbacks actions
      end
    end
  end
end
