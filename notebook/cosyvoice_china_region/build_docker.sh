model_name=$1

case "$model_name" in
    "CosyVoice-300M" | "CosyVoice-300M-SFT" | "CosyVoice-300M-Instruct" | "speech_kantts_ttsfrd")
        echo "select model - $model_name"
        ;;
    *)
        echo "invalid CosyVoice model"
        ;;
esac
    
algorithm_name=$(echo $model_name | tr '[:upper:]' '[:lower:]')

account=$(aws sts get-caller-identity --query Account --output text)

# Get the region defined in the current configuration (default to us-west-2 if none defined)
region=$(aws configure get region)

fullname="${account}.dkr.ecr.${region}.amazonaws.com/${algorithm_name}:latest"

# If the repository doesn't exist in ECR, create it.

aws ecr describe-repositories --repository-names "${algorithm_name}" > /dev/null 2>&1
if [ $? -ne 0 ]
then
aws ecr create-repository --repository-name "${algorithm_name}" > /dev/null
fi

#load public ECR image
#aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
docker pull pytorch/pytorch:2.0.1-cuda11.7-cudnn8-runtime
echo "pull finished"
# Log into Docker
pwd=$(aws ecr get-login-password --region ${region})
docker login --username AWS -p ${pwd} ${account}.dkr.ecr.${region}.amazonaws.com

# Build the docker image locally with the image name and then push it to ECR
# with the full name.
docker build --build-arg MODEL_NAME=${model_name} -t ${algorithm_name}  ./ -f ./Dockerfile
docker tag ${algorithm_name} ${fullname}
docker push ${fullname}