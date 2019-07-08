This repository, like `worker-aws`, contains a specification for how to build an EC2 AMI. Unlike `worker-aws`, this repository contains the specification for how to build the instance with Tango and Autolab set up.

Further unlike `worker-aws`, the image created from this specification has the potential to become either a dev or a prod instance of Notolab. Once you create an instance from the image and decide whether it should be a dev or prod instance, you can just run the appropriate script `make_prod` or `make_dev`, and the instance will be set up appropriately if you follow the prompts in the script. Then, to start the webserver, just run `./startup.sh`.

The following bulleted list contains a more precise description of how exactly to set up a new instance of Notolab, either dev or prod.
  1. Log into the AWS organization. In Fall 2019, this was `cmu-15-411`. To gain access to the AWS organization, you will either have to ask the current professor or a course staff member from the previous semester. They can add a new AMI user for you, or they can just give you the root password.
  2. Navigate to the EC2 dashboard. Ensure that the region is set to `us-east-1 (N. Virginia)`&mdash;you control this setting from the top-right of the UI.
  3. Navigate to the "instances" page of the EC2 dashboard. See what instances are currently running or stopped. There might already be a Notolab dev or prod instance from the previous semester, in which case you can just start it up again using the "Instance State" submenu. But if you actually want to create a fresh Notolab dev or prod instance, continue to the next item.
  4. Navigate to the "AMIs" page of the EC2 dashboard. This lists all available images. You'll see both Autolab and worker images&mdash;the Autolab images are for creating dev/prod instances of notolab; the worker images are used by Notolab for creating instances that autograde student work. The timestamp on the AMI corresponds to when commits were pushed to GitHub, so you should choose the latest version of the Autolab image.
  5. Create an instance from the latest Autolab image. This involves: Choosing the latest Autolab image as the AMI, setting the storage to 20 GB (at least; the default 8 GB probably won't be enough), setting the security group to 15-411 Manager, and, upon launching the instance, choosing `411-f19.pem` as the security key in the menu that pops up.
  6. Wait for the instance to start up, looking at the Instances page of the EC2 dashboard. Once it has, ssh in as `ubuntu@XX.XXX.XX` (replacing the Xs with the appropriate IP address) and using the ssh key `411-f19.pem` (which you will have to obtain from someone on the course staff from last semester, probably by asking them to add your public SSH key to the old dev notolab server so you're able to SCP the key from there).
  7. Once you are sshed into the instance, run the `make_dev` or `make_prod` script from the ubuntu home directory. (These will perform setup based on whether you want the instance to be dev or prod notolab.)
  8. Once the setup is complete, you should run the `startup.sh` script that was placed in the home directory to start the web server.
  9. Navigate to the Elastic IP page of the EC2 dashboard. Point the elastic IP for dev or prod Notolab toward the new running instance.
  10. Test that you can access the new instance at dev.notolab.ml or notolab.ml. You can terminate the old instance of dev or prod notolab, if there was one running in step 3.

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
