=begin
====================================================================

Ajo
Copyright (c) 2012-2013 RDlab, LSI, UPC BarcelonaTech.

This file is part of Ajo.

Ajo is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Ajo is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Ajo. If not, see <http://www.gnu.org/licenses/>.

====================================================================
=end

module Hpc
  def ssh(command)
    `#{SSH_CMD} '#{command}'`.chomp("\n")
  end

  def copy_files(remote_temp_dir)
    $LOG.info "Started copying files. Will be working with the remote temp directory #{remote_temp_dir}"
    file_args = FILE_ARGS.reject { |_, value| value.empty? }
    $LOG.info "Prepared FILE_ARGS by rejecting empty elements"
    if not file_args.empty?
      $LOG.info "The file argument block is not empty"
      tempdir = Dir.mktmpdir("ajo")
      $LOG.info "Created temporary directory at #{tempdir}"
      archive = tempdir + "/archive.tar"
      `tar cfT #{archive} /dev/null`
      $LOG.info "Created tar archive at #{archive}"
      file_args.each do |key, value|
        `tar -C #{File.dirname(value)} -rf #{archive} #{File.basename(value)}`
        $LOG.info "Added the file #{value} to the tar archive"
        # here we change local file names to the new remote ones
        # to be able to process them correctly on the server
        file_args[key] = remote_temp_dir + "/" + File.basename(value)
        $LOG.info "The file's remote path is #{file_args[key]}"
      end
      `cat #{tempdir}/archive.tar | #{SSH_CMD} 'tar -C #{remote_temp_dir} -xf -'`
      if $?.to_i != 0
        $LOG.error "SSH error occured, exit information is #{$?.to_s}" 
        abort "SSH error occured."
      end
      $LOG.info "Copied and unextracted the tar archive to #{remote_temp_dir}"
      FileUtils.remove_entry_secure(tempdir)
      $LOG.info "Removed the temporary directory at #{tempdir}"
    end
    $LOG.info "copy_files will exit now"
    file_args
  end

  def copy_folders(remote_temp_dir)
    $LOG.info "Started copying folders. Working with the temporary directory #{remote_temp_dir}"
    folder_args = FOLDER_ARGS.reject { |_, value| value.empty? }
    $LOG.info "Prepared FOLDER_ARGS by rejecting empty values."
    if not folder_args.empty?
      $LOG.info "folder arguments are not empty"
      folder_args.each do |key, value|
        `tar -C #{File.dirname(value)} -czf - #{File.basename(value)} |\
        #{SSH_CMD} 'tar -C #{remote_temp_dir} -xzf -'`
        if $? != 0
          $LOG.error "SSH error occured. The exit information is #{$?.to_s}" 
          abort "SSH error occured."
        end
        $LOG.info "Copied the folder #{value}"
        # here we change local folder names to the new remote ones
        # to be able to process them correctly on the server
        folder_args[key] = remote_temp_dir + "/" + File.basename(value)
        $LOG.info "The remote path of the transferred folder is #{folder_args[key]}"
      end
    end
    $LOG.info "copy_folders will now exit"
    folder_args
  end

  def prepare_output_files(remote_output_dir)
    $LOG.info "Started preparing output files. Working with the remote directory #{remote_output_dir}"
    file_output = FILE_OUTPUT.reject { |_, value| value.empty? }
    $LOG.info "Rejected the empty items"
    if not file_output.empty?
      $LOG.info "FILE_OUTPUT is not empty"
      file_output.each do |key, value|
        file_to_create = remote_output_dir + "/" + File.basename(value)
        ssh("touch #{file_to_create}")
        if $? != 0
          $LOG.error "SSH error occured. Exit information is #{$?.to_s}"
          abort "SSH error occured."
        end
        $LOG.info "Created output file #{file_to_create}"
        file_output[key] = file_to_create
      end
    end
    $LOG.info "file_output will now exit"
    file_output
  end

  def prepare_output_folders(remote_output_dir)
    $LOG.info "Started preparing output folders. Working with the remote directory #{remote_output_dir}"
    folder_output = FOLDER_OUTPUT.reject { |_, value| value.empty? }
    $LOG.info "Rejected the empty items"
    if not folder_output.empty?
      $LOG.info "Folder output block is not empty"
      folder_output.each do |key, value|
        dir_to_create = remote_output_dir + "/" + File.basename(value)
        ssh("mkdir #{dir_to_create}")
        if $? != 0
          $LOG.error "SSH error occured. Exit information is #{$?.to_s}"
          abort "SSH error occured."
        end
        folder_output[key] = dir_to_create
        $LOG.info "Created the remote directory #{dir_to_create}"
      end
    end
    $LOG.info "folder_output will now exit"
    folder_output
  end

  def create_remote_temp_dir
    $LOG.info "Started creating remote temp dir"
    # create remote temp directory in the AJO directory: $HOME/.executions
    # we use the template (-t) to make the directories look like
    # $HOME/.executions/XXXXXXXXXX (exactly 10 characters in the basename)
    command = %{mkdir -p #{AJO_DIR} &&\
               mktemp -t XXXXXXXXXX --tmpdir=#{AJO_DIR} -d}
    result = ssh(command)
    $LOG.info "Created the remote temporary directory #{result}"
    result
  end

  def create_remote_output_dir(remote_temp_dir)
    $LOG.info "Started creating remote output dir. Working with the remote temporary directory #{remote_temp_dir}"
    remote_output_dir = remote_temp_dir + "/output"
    ssh("mkdir -p #{remote_output_dir}")
    if not $? == 0
      $LOG.error "SSH error occured. The exit information is #{$?.to_s}"
      abort "SSH error occured."
    end
    $LOG.info "Created the remote output directory #{remote_output_dir}"
    remote_output_dir
  end

  def create_local_batch_file(commands)
    $LOG.info "Started creating local batch file"
    if commands.empty?
      $LOG.error "No commands supplied"
      abort "No commands supplied"
    end
    batch_file_path = nil
    Tempfile.open(["ajo", ".tmp"]) do |batch_file|
      batch_file.puts commands
      batch_file_path = batch_file.path
      $LOG.info "Created a local batch file at #{batch_file.path}"
    end
    batch_file_path
  end

  def create_remote_batch_file(local_batch_file, remote_temp_dir)
    $LOG.info "Started creating remote batch file from local one at #{local_batch_file} at the remote
    directory #{remote_temp_dir}"
    remote_batch_file = remote_temp_dir + "/batch.sh"
    `cat #{local_batch_file} | #{SSH_CMD} 'cat > #{remote_batch_file}'`
    if $? != 0
      $LOG.error "SSH error occured. The exit information is #{$?.to_s}"
      abort "SSH error occured."
    else
      $LOG.info "Created the remote batch file at #{remote_batch_file}"
    end
    $LOG.info "create_remote_batch_file will now exit"
    remote_batch_file
  end

  def submit
    remote_temp_dir = create_remote_temp_dir
    $LOG.info "Created remote temporary directory at #{remote_temp_dir}"
    remote_output_dir = create_remote_output_dir remote_temp_dir
    $LOG.info "Created remote output directory at #{remote_output_dir}"
    file_args = copy_files remote_temp_dir
    $LOG.info "Processed the file arguments"
    folder_args = copy_folders remote_temp_dir
    $LOG.info "Processed the folder arguments"
    file_output = prepare_output_files remote_output_dir
    $LOG.info "Processed the file output"
    folder_output = prepare_output_folders remote_output_dir
    $LOG.info "Processed the folder output"
    commands = process_commands file_args, folder_args, file_output, folder_output, remote_temp_dir, remote_output_dir
    $LOG.info "Processed the commands"
    # uncomment to put commands to the log file
    # $LOG.info commands

    # exit if no commands have been supplied
    if commands.empty?
      $LOG.error "No commands supplied. Exit"
      return 1
    end
    local_batch_file = create_local_batch_file commands
    $LOG.info "Created local batch file at #{local_batch_file}"
    remote_batch_file = create_remote_batch_file local_batch_file, remote_output_dir
    $LOG.info "Copied the created batch file as #{remote_batch_file}"

    jobid = ssh("#{QSUB_CMD} -o #{remote_output_dir}/std.out\
     -e #{remote_output_dir}/std.err #{remote_batch_file}")[/\d{7}/]
    $LOG.info "Received the jobid #{jobid}"
    job_info = {:jobid => jobid, :temp_dir => File.basename(remote_temp_dir)}
    $LOG.info "Created the job_info hash #{job_info.inspect}. Removing local batch file"
    `rm #{local_batch_file}`
    $LOG.info "Encoding the job_info hash"
    encoded = encode(job_info)
    ssh("echo #{encoded} > #{remote_temp_dir}/.ajo")
    $LOG.info "Wrote the encoded identifier to the #{remote_temp_dir}/.ajo file. Will now exit"
    encoded
  end

  def encode(job_info)
    $LOG.info "Started encoding the job info. Received the hash #{job_info.inspect}"
    cipher = OpenSSL::Cipher::AES.new(128, :CBC)
    cipher.encrypt
    cipher.key = CIPHER_KEY
    cipher.iv = CIPHER_IV
    encrypted = cipher.update(job_info.inspect) + cipher.final
    $LOG.info "Encoding completed. encode will now exit"
    encrypted.unpack('H*').first
  end

  def decode(identifier)
    $LOG.info "Started decoding the job info. Received the identifier #{identifier}"
    encrypted = [identifier].pack('H*')
    cipher = OpenSSL::Cipher::AES.new(128, :CBC)
    cipher.decrypt
    cipher.key = CIPHER_KEY
    cipher.iv = CIPHER_IV
    decrypted = cipher.update(encrypted) + cipher.final
    job_info = eval(decrypted)
    $LOG.info "Decoded the temporary directory #{job_info[:temp_dir]}"
    $LOG.info "Decoded the job id. Created the job info hash #{job_info.inspect}"
    $LOG.info "decode will now exit"
    job_info
  end

  def query(job_info)
    $LOG.info "Started the query process. Received the job_info #{job_info}"
    # get the statistics qstat information for current user via ssh
    command = "#{QSTAT_CMD} -u #{USER} | grep #{job_info[:jobid]}"
    userstats = ssh(command)
    # if exit status is 255, than there was an ssh error
    if $? == 255
      $LOG.error "SSH problem occured. The exit information is #{$?.to_s}. Exiting"
      $LOG.error "The connection was performed with the command #{command}"
      $LOG.error "userstats value before exit is #{userstats}"
      return 255
    end

    # if userstats is not empty, then the job is running
    if not userstats.empty?
      $LOG.info "Userstats not empty - the job is running. Userstats: #{userstats}."
      $LOG.info "query will now exit"
      return 1
    end

    job_qacct = ssh("#{QACCT_CMD} -j #{job_info[:jobid]} 2>&1")
    $LOG.info "Got information about the job from qacct. Got this: #{job_qacct}"
    # if the return status of this ssh query is 1, then this job never existed
    # otherwise, it has successfully finished running
    if not job_qacct["error"].nil?
      $LOG.info "Qacct response empty, the job never existed. query will now exit"
      return 2
    else
      # check if the folder with results exists
      directory = ssh("if test -d #{AJO_DIR}/#{job_info[:temp_dir]}; then echo \'true\'; else echo \'false\'; fi")
      if directory == "false"
        $LOG.info "The job folder has been erased"
        return 2
      else
        $LOG.info "The job has finished running. query will now exit"
        return 0
      end
    end
  end

  def retrieve(job_info, retrieve_dir, retrieve_hash)
    retrieve_files = retrieve_hash.reject {|_, value| value.empty?}
    remote_home = ssh('echo $HOME')
    $LOG.info "Got information about remote home directory. It seems to be #{remote_home}"
    remote_output_dir = AJO_DIR + "/" + job_info[:temp_dir] + "/output"
    $LOG.info "Remote output directory seems to be #{remote_output_dir}"
    if not retrieve_files.empty?
      archive = File.dirname(remote_output_dir) + "/archive.tar"
      ssh("tar cfT #{archive} /dev/null")
      $LOG.info "Created empty tar archive at #{archive}"
      retrieve_files.each do |_, value|
        ssh("tar -C #{remote_output_dir} -rf #{archive} #{File.basename(value)}")
        $LOG.info "Added file #{value} to the archive"
      end
      `#{SSH_CMD} 'cat #{archive}' | tar -C #{retrieve_dir} -xf -`
      $LOG.info "Extracted archive to #{retrieve_dir}"
    end
  end

  def erase(job_info)
    query_result = query(job_info)
    if query_result != 0
      $LOG.info "Some error occured while cancelling the job"
      abort "The job has not been finished o had never existed"
    end
    $LOG.info "Will now erase the directory #{job_info[:temp_dir]}"
    remote_dir = AJO_DIR + "/" + job_info[:temp_dir]
    ssh("rm -r #{remote_dir}")
    $LOG.info "Done erasing"
  end

  def cancel(job_info)
    $LOG.info "Will now cancel the job #{job_info[:jobid]}"
    result = ssh("#{QDEL_CMD} #{job_info[:jobid]}")
    if not result["denied"].nil?
      $LOG.error "Job does not exist, cancelling failed"
      abort "Unable to cancel the job: it has been finished or had never existed"
    else
      $LOG.info "Done cancelling"
    end
  end

  def retrieve_all(job_info, retrieve_dir)
    # get the full path of the remote output directory
    full_remote_output_dir = AJO_DIR + "/" + job_info[:temp_dir] + "/output"
    # retrieve output folders and files and store them at the local temp directory
    `#{SSH_CMD} 'tar -C #{full_remote_output_dir} -czf - ./' | tar -C #{retrieve_dir} -xzf -`
  end

  def list
    array = ssh("for D in \`ls #{AJO_DIR}\`; do cat #{AJO_DIR}/$D/.ajo 2> /dev/null; done").split("\n")
    puts array
  end
end
