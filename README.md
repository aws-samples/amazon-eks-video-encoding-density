# Media streaming with fractional GPUs on Amazon EKS

This example shows how to configure an Amazon EKS cluster using time-sliced GPUs. This example uses Bottlerocket for the container operating system, Karpenter for autoscaling and deploys an ffmpeg workload to test encoding density on various GPU instances. The workload is packaged using a multi-arch container image so that it can be deployed on different CPU processor architectures. 

This example uses the following software:

- [Linux Server](https://github.com/linuxserver/docker-ffmpeg) - The FFMPEG docker image used in this sample is based heavily on the version maintained by Linux Server.
- [FFmpeg](https://ffmpeg.org/) - A complete, cross-platform solution to record, convert and stream audio and video.
- [Bottlerocket](https://bottlerocket.dev/) - Minimal container OS.
- [Karpenter](https://karpenter.sh/) - Just in time node scaling for Kubernetes.

**N.B.:** Although this repository is released under the MIT-0 license, its Dockerfile uses the third party linuxserver/docker-ffmpeg and FFmpeg projects. These project's licensing includes the GPL-3.0 license.

# Setup

## Set the required environment variables to match your environment

```
export KARPENTER_NAMESPACE=karpenter
export KARPENTER_VERSION=v0.33.0
export K8S_VERSION=1.28
export AWS_PARTITION="aws"
export CLUSTER_NAME="br-cluster"
export AWS_DEFAULT_REGION="us-east-1"
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export TEMPOUT=$(mktemp)
```

## Add media files to test streaming

Add the example file you want to use with FFmpeg for testing e.g:

`
wget https://download.blender.org/demo/movies/BBB/bbb_sunflower_1080p_30fps_normal.mp4.zip`

If needed, unzip:

`
unzip bbb_sunflower_1080p_30fps_normal.mp4.zip
`

Uncomment in the bottom of the dockerfile to include the test video in the container image:
```
COPY ./bbb_sunflower_1080p_30fps_normal.mp4 ./bbb_sunflower_1080p_30fps_normal.mp4
```

(Optional) convert the downloaded file to different framerates (e.g. 25fps) using [AWS Elemental MediaConvert](https://docs.aws.amazon.com/mediaconvert/latest/ug/getting-started.html):
```
COPY ./bbb_sunflower_1080p_25fps_normal.ts ./bbb_sunflower_1080p_25fps_normal.ts
```

## Build the multi-arch image and push to ECR

Be sure to log in to ECR first, e.g:

`
aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com
`

`
docker buildx build --platform "linux/amd64,linux/arm64" --tag ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/ffmpeg:1.0 --push  . -f Dockerfile
`
## Create the EKS Cluster using eksctl

```
curl -fsSL https://raw.githubusercontent.com/aws/karpenter-provider-aws/"${KARPENTER_VERSION}"/website/content/en/preview/getting-started/getting-started-with-karpenter/cloudformation.yaml  > $TEMPOUT \
&& aws cloudformation deploy \
  --stack-name "Karpenter-${CLUSTER_NAME}" \
  --template-file "${TEMPOUT}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "ClusterName=${CLUSTER_NAME}"
```

`envsubst < cluster.yaml | eksctl create cluster -f -`

Configure the NVIDIA daemonset to use the latest device plugin and configure for time-slicing:

```
kubectl delete daemonset nvidia-device-plugin-daemonset -n kube-system
kubectl create -n kube-system -f time-slicing-config-all.yaml
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update
helm upgrade -i nvdp nvdp/nvidia-device-plugin \
    --version=0.14.1 \
    --namespace kube-system \
    --create-namespace \
    --set config.name=time-slicing-config-all
```

Install Karpenter [as per the Karpenter documentation](https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/). Create a NodePool and EC2NodeClass:

```
export CLUSTER_ENDPOINT="$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.endpoint" --output text)"
export KARPENTER_IAM_ROLE_ARN="arn:${AWS_PARTITION}:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER_NAME}-karpenter"

echo $CLUSTER_ENDPOINT $KARPENTER_IAM_ROLE_ARN

helm registry logout public.ecr.aws

helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --version "${KARPENTER_VERSION}" --namespace "${KARPENTER_NAMESPACE}" --create-namespace \
  --set "settings.clusterName=${CLUSTER_NAME}" \
  --set "settings.interruptionQueue=${CLUSTER_NAME}" \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi \
  --wait
```

```
envsubst < provisioner.yaml | kubectl apply -f -
```

Create a deployment using the multi-arch container image:

```
envsubst < deployment.yaml | kubectl apply -f -
````

Test scaling the deployment:

```
kubectl scale deployment ffmpeg-deployment --replicas 30 
```

Be sure to scale back down once testing is complete to save costs:

```
kubectl scale deployment ffmpeg-deployment --replicas 0
```

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

