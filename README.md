This repository, like `worker-aws`, contains a specification for how to build an EC2 AMI. Unlike `worker-aws`, this repository contains the specification for how to build the instance with Tango and Autolab set up.

Further unlike `worker-aws`, the image created from this specification has the potential to become either a dev or a prod instance of Notolab. Once you create an instance from the image and decide whether it should be a dev or prod instance, you can just run the appropriate script `make_prod` or `make_dev`, and the instance will be set up appropriately if you follow the prompts in the script. Then, to start the webserver, just run `./startup.sh`.

The secret information needed to be encoded in this repository is as follows:
  * `AWS_ACCESS_KEY`: the AWS access key for an AMI user that can build images.
  * `AWS_SECRET_KEY`: the AWS secret key for an AMI user that can build images.
  * `MAILER_USERNAME`: the username given for AWS mailer user when creating the user.
  * `MAILER_PASSWORD`: the password given for AWS mailer user when creating the user.
  * `secret_files.tar.gz`: an archive containing the following files:
    * `411-f19.pem`: a file containing the SSH key for AWS instances.
    * `passwords.json`: a file containing the plaintext passwords for all CMU-15-411&ndash;affiliated accounts.

See the instructions in `worker-aws` for how to encode these secrets. You will use `travis encrypt` for `AWS_ACCESS_KEY` and `AWS_SECRET_KEY` (and for the `MAILER` stuff), and `travis encrypt-file` for `secret_files.tar.gz`. As in `worker_aws`, these values are currently available, but if you ever need to change AWS organizations or GitHub users, you will know how to encode these.

`travis encrypt-files` does NOT work for multiple files; that's why we're using a tar archive here. The file `secret_files.tar.gz` won't be stored directly in the repo, but `secret_files.tar.gz.enc` will be (which is the output from encrypting the tar archive). To update either the secret key or the passwords.json file, you'll have to take the original, unencrypted files (probably from Dev or Prod Notolab), edit those files, and re-tar and re-encrypt the archive.

It won't work to just copy the encrypted keys and files from the `worker-aws` repository, since Travis generates a separate key pair for each repository.
