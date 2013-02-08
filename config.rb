# ajo sample configuration file
# Format of the config file is Ruby, feel free to use any expressions
# from Ruby language.

module Hpc
  # SSH options
  SERVER = "server.name.domain"
  USER = "username" # insert your Linux username between quotes
  SSH_CMD = "/usr/bin/ssh #{USER}@#{SERVER}"
  AJO_DIR = `#{SSH_CMD} 'echo $HOME'`.chomp("\n") + "/.executions"

  # SGE options, normally you will not have to change this.
  SGE_ROOT = `#{SSH_CMD} 'echo $SGE_ROOT'`.chomp "\n"
  SGE_ARCH = `#{SSH_CMD} '#{SGE_ROOT}/util/arch'`.chomp "\n"
  SGE_UTIL_PATH = SGE_ROOT + "/bin/" + SGE_ARCH
  QSUB_CMD = SGE_UTIL_PATH + "/qsub"
  QSTAT_CMD = SGE_UTIL_PATH + "/qstat"
  QACCT_CMD = SGE_UTIL_PATH + "/qacct"
  QDEL_CMD = SGE_UTIL_PATH + "/qdel"

  # Encryption options, replace USER and SERVER in second and third lines with
  # something random for more security. But be careful - loosing CIPHER_KEY
  # and CIPHER_IV will make decoding your job identifier impossible.
  CIPHER_SALT = "ajo"
  CIPHER_KEY = OpenSSL::PKCS5.pbkdf2_hmac_sha1(USER, CIPHER_SALT, 2000, 16)
  CIPHER_IV = OpenSSL::PKCS5.pbkdf2_hmac_sha1(SERVER, CIPHER_SALT, 2000, 16)

  # Set the folder arguments that you want to submit to the cluster
  # here by putting the directory path between the double quotes, like this:
  # :fld1 => "~/folder42"
  # The word on the left that starts with a colon (like :fld1) is the key,
  # with which you will later be able to access these folders inside the command.
  # Feel free to add any quantity of arguments, just keep the same format.
  FOLDER_ARGS = {
    #:fld1 => "~/folder42",
    :fld2 => "",
    :fld3 => "",
    :fld4 => "",
    :fld5 => "",
    :fld6 => "",
    :fld7 => "",
  }

  # Here you can put the file arguments you want to submit to the cluster.
  # The format is the same as one used for the folders.
  FILE_ARGS = {
    #:file1 => "~/file42",
    :file2 => "",
    :file3 => "",
    :file4 => "",
    :file5 => "",
    :file6 => "",
    :file7 => "",
  }

  # In this block you can set the folders that will be created for use as output
  # directories. You can use them in the commands just like folder and file arguments.
  FOLDER_OUTPUT = {
    #:fld1 => "outputfolder42",
    :fld2 => "",
    :fld3 => "",
  }

  # The same thing, but for output files.
  FILE_OUTPUT = {
    #:file1 => "file1.txt",
  }

  # This block sets the names of the output files you want to download with
  # 'hpc --retrieve'.
  RETRIEVE = {
    #:folder1 => "file1.txt",
  }

  # Finally, the commands to execute. You can use the output files and folders inside
  # the commands by typing #{%constant_name[%file_key]} inside the command string,
  # for example:
  # "cat #{FILE_ARGS[:file1]}"
  # Constants you can use are file_args, folder_args, file_output and folder_output,
  # the ones you filled with files and folders above, but in *lowercase* (that's very important).
  # Type commands between double quotes, and separate different commands with a comma.
  def process_commands file_args, folder_args, file_output, folder_output, input_dir, output_dir
    [
      #"uname -a > #{file_output[:file1]}",
      #"echo 'hello' > #{file_output[:file1]}"
    ]
  end
end
