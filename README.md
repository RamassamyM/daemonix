# daemonix
Module to add for managing daemons.
This module is working on top of the [gem Daemons](https://github.com/thuehlinger/daemons).
[See the gem documentation](https://www.rubydoc.info/gems/daemons/Daemons)

The gem daemons is used by launching commands in terminal. This module makes it possible to have ruby script to manage daemons.

### Installation

Paste folder daemonix in lib folder in rails
and configure application.rb to automatically load files in lib folder if necessary :

```ruby
class Application < Rails::Application
  ...
  config.autoload_paths += %W(#{config.root}/lib)
  ...
end
```

### How to use


#### Starting a process in daemon


You can just start a process :
```ruby
Daemonix::DaemonProcess.start
```
It will launch the daemon and respond with a hash containing the process_name, the pid (process id in unix), and the pid_directory (the gem daemons store the pid in a file processs_name.pid in a directory).

By default, a time stamps is added to the process_name to differentiate daemons with the same process_name.


You can configure the process_name and the directory_path :
```ruby
Daemonix::DaemonProcess.start(process_name: 'my_process_name')
```

```ruby
Daemonix::DaemonProcess.start(process_name: 'my_process_name', pid_directory: './my_directorypath')
```


To make daemon useful, you need to indicates what will be launched as a daemon process by giving a block or proc or lambda.

```ruby
Daemonix::DaemonProcess.start { proc_or_lambda }
```

### Listing all running daemons

```ruby
Daemonix::DaemonProcess.index
```



### Stopping daemons

To stop a daemon, you need to specify the process_name and the pid_directory : 

```ruby
Daemonix::DaemonProcess.stop('process_name', 'pid_directory') 
```


You can also stop a process with only the pid number, but il will not delete the pid_file generated by the gem daemon :

```ruby
Daemonix::DaemonProcess.stop_process(pid)
```


You can stop all running processes :
```ruby
Daemonix::DaemonProcess.stop_all
```



### Checking if a process is running

```ruby
Daemonix::DaemonProcess.running?(pid)
```



## TIP

To see all ruby processes running in terminal : 

```bash
pgrep ruby
```
