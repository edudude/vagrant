require "ostruct"

require "log4r"

require "vagrant/util/subprocess"

module Vagrant
  module EasyCommand
    # This class contains all the "operations" that easy commands are able
    # to run. An instance of this is class is what is sent into the callback
    # for all easy commands.
    class Operations
      def initialize(vm)
        @logger = Log4r::Logger.new("vagrant::easy_command::operations")
        @vm = vm
      end

      # Runs a command on the local machine. This will return an object where
      # you can access the `exit_code`, `stdout`, and `stderr` easiy:
      #
      #     output = local("echo foo")
      #     puts "Output was #{output.stdout}"
      #
      # (Likewise, `exit_code` and `stderr` are attributes on the return value)
      #
      # It is recommended you use this `local` method rather than trying to
      # manually use Ruby's underlying subprocess tools because this will use
      # the Vagrant `Subprocess` class which has been refined over the years
      # to work equally well on Windows, Mac OS X, Linux as well as on many
      # runtimes such as CRuby and JRuby.
      #
      # @param [String] command Command to run
      def local(command)
        @logger.info("local: #{command}")
        Vagrant::Util::Subprocess.execute(command)
      end

      # Run a shell command within the VM. The command will run within a
      # shell environment, and the output and exit code will be returned
      # as an object with attributes: `exit_code, `stdout`, and `stderr`.
      # Example:
      #
      #     output = run("echo foo")
      #     puts "Output was #{output.stdout}"
      #
      # @param [String] command Command to run
      def run(command)
        @logger.info("run: #{command}")
        remote_command(:execute, command)
      end

      # Same as {run} except runs the command with superuser privileges
      # via `sudo`.
      #
      # @param [String] command Command
      def sudo(command)
        @logger.info("sudo: #{command}")
        remote_command(:sudo, command)
      end

      protected

      # Runs a command on the remote host.
      def remote_command(type, command)
        # If the VM is not running, then we can't run SSH commands...
        raise Errors::VMNotRunningError if @vm.state != :running

        # Initialize the result object, execute, and store the data
        result = OpenStruct.new
        result.stderr = ""
        result.stdout = ""
        result.exit_code = @vm.channel.send(type, command,
                                            :error_check => false) do |type, data|
          if type == :stdout
            result.stdout += data
          elsif type == :stderr
            result.stderr += data
          end
        end

        # Return the result
        result
      end
    end
  end
end
