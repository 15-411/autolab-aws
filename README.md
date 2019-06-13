This repository, like `worker-aws`, contains a specification for how to build an EC2 AMI. Unlike `worker-aws`, this repository contains the specification for how to build the instance with Tango and Autolab set up.

Further unlike `worker-aws`, the image created from this specification has the potential to become either a dev or a prod instance of Notolab. Once you create an instance from the image and decide whether it should be a dev or prod instance, you can just run the appropriate script `make_prod` or `make_dev`, and the instance will be set up appropriately if you follow the prompts in the script. Then, to start the webserver, just run `./startup.sh`.

The secret information needed to be encoded in this repository is as follows:
  * `AWS_ACCESS_KEY`: the AWS access key for an AMI user that can build images.
  * `AWS_SECRET_KEY`: the AWS secret key for an AMI user that can build images.
  * `MAILER_ACCESS_KEY`: the AWS access key for an AMI user that can send mail.
  * `MAILER_SECRET_KEY`: the AWS secret key for an AMI user that can send mail.
  * `cmu-15-411-bot-key`: a file containing a GitHub SSH key for the user cmu-15-411-bot.

See the instructions in `worker-aws` for how to encode these secrets. You will use `travis encrypt` for `AWS_ACCESS_KEY` and `AWS_SECRET_KEY` (and for the `MAILER` stuff), and `travis encrypt-file` for `cmu-15-411-bot-key`. As in `worker_aws`, these values are currently available, but if you ever need to change AWS organizations or GitHub users, you will know how to encode these.

It won't work to just copy the encrypted keys and files from the `worker-aws` repository, since Travis generates a separate key pair for each repository.
