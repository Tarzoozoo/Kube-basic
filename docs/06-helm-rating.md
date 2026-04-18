# Convert Rating Service to Helm

### ถ้ามีหลายenv (dev, uat, prd) จะต้อง copy paste ตัวแปรที่ซ้ำๆกันให้ตรงตาม env นั้นๆ
### วิธีที่แนะนำคือ Manifeat file --> Helm chart (template) แล้วแก้ไขตัวแปรผ่าน value file แทน

## Create Helm Chart for Ratings Service

* Delete current Ratings Service first with command `kubectl delete -f k8s/`
* `mkdir ~/ratings/k8s/helm` to create directory for Ratings Helm Charts
* Create `Chart.yaml` file inside `helm` directory and put below content

```yaml
apiVersion: v1
description: Bookinfo Ratings Service Helm Chart
name: bookinfo-ratings
version: 1.0.0
appVersion: 1.0.0
home: https://bookinfo.demo.opsta.net/ratings
maintainers:
  - name: Developer
    email: skooldio@opsta.net
```

* `mkdir ~/ratings/k8s/helm/templates` to create directory for Helm Templates
* Move our ratings manifest file to template directory with command `mv k8s/ratings-*.yaml k8s/helm/templates/`
* Let's try deploy Ratings Service

```bash
# Deploy Ratings Helm Chart
# Release name = bookinfo-dev-ratings
cd ~/ratings
helm install bookinfo-dev-ratings k8s/helm

# Get Status
kubectl get pod,deploy,svc,ingress
kubectl get deployment
kubectl get pod
kubectl get service
kubectl get ingress

# Get helm; You will found Release Name
helm list
```

* Try to access <https://bookinfo.dev.opsta.net/ratings/health> and <https://bookinfo.dev.opsta.net/ratings/ratings/1> to check the deployment

### *** สรุป Helm chart ทำงานโดยการ Copy manifest file --> templates แล้ว Deploy ด้วย Helm install

## Create Helm Value file for Ratings Service

* Create `values-bookinfo-dev-ratings.yaml` file inside `k8s/helm-values` directory and put below content

```yaml
ratings:
  namespace: bookinfo-dev
  image: asia.gcr.io/[PROJECT_ID]/bookinfo-ratings
  tag: dev
  replicas: 1
  imagePullSecrets: registry-bookinfo
  port: 9080
  healthCheckPath: "/health"
  mongodbPasswordExistingSecret: bookinfo-dev-ratings-mongodb-secret
ingress:
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /$2
  host: bookinfo.dev.opsta.net
  path: "/ratings(/|$)(.*)"
  serviceType: ClusterIP
extraEnv:
  SERVICE_VERSION: v2
  MONGO_DB_URL: mongodb://bookinfo-dev-ratings-mongodb:27017/ratings-dev
  MONGO_DB_USERNAME: ratings-dev
```

* Let's replace variable one-by-one with these object
  * `{{ .Release.Name }}`
  * `{{ .Values.ratings.* }}`
  * `{{ .Values.ingress.* }}`
* This is sample syntax to have default value

```yaml
{{ .Values.ingress.path | default "/" }}
```

* This is a sample of using if and range syntax

```yaml
        {{- if .Values.extraEnv }}
        env:
        {{- range $key, $value := .Values.extraEnv }}
        - name: {{ $key }}
          value: {{ $value | quote }}
        {{- end }}
        {{- if .Values.ratings.mongodbPasswordExistingSecret }}
        - name: MONGO_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ .Values.ratings.mongodbPasswordExistingSecret }}
              key: mongodb-password
        {{- end }}
        {{- end }}
```

* This is sample syntax to loop annotation

```yaml
  {{- if .Values.ingress.annotations }}
  annotations:
  {{- range $key, $value := .Values.ingress.annotations }}
    {{ $key }}: {{ $value | quote }}
  {{- end }}
  {{- end }}
```

* After replace, you can upgrade release with below command

```bash
helm upgrade -f k8s/helm-values/values-bookinfo-dev-ratings.yaml \
  bookinfo-dev-ratings k8s/helm
```

```bash
# Test and Revision will increase
helm list
kubectl get pod,deploy,svc,ingress

# helm upgrade will not interfere other resources
```

## Exercise: Deploy on UAT and Production Environment

* Create Helm value and deploy for UAT and Production environment
* Create Kubernetes & Helm deployment for `details`, `reviews`, and `productpage` services

### Hints
* Prepare Helm Values for mongodb and ratings
* Change namespace (context) to uat environment
* Add configmap and secret
* Helm install mongodb release
* Helm install ratings release


## UAT
* Prepare Helm Values for mongodb and ratings
* Change namespace (context) to uat environment
```bash
kubectl config get-contexts
kubectl config set-context $(kubectl config current-context) --namespace=bookinfo-uat
```

* Add configmap and secret
```bash
cd ~/ratings
# Create configmap
kubectl create configmap bookinfo-uat-ratings-mongodb-initdb \
  --from-file=databases/ratings_data.json \
  --from-file=databases/script.sh

# Create Kubernetes Secret via Docker credentials
kubectl create secret generic registry-bookinfo \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson
```

* Helm install mongodb release
```bash
# Deploy new MongoDB with Custom Helm Value of Helm Chart
helm install -f k8s/helm-values/values-bookinfo-uat-ratings-mongodb.yaml \
  bookinfo-uat-ratings-mongodb bitnami/mongodb
```

* Helm install ratings release
```bash
# Deploy Ratings Helm Chart
# Release name = bookinfo-uat-ratings
cd ~/ratings
helm install -f k8s/helm-values/values-bookinfo-uat-ratings.yaml \
  bookinfo-uat-ratings k8s/helm

# Get Status
kubectl get pod,deploy,svc,ingress

# Troubleshooting
kubectl describe pod pod_name

# ลืม create secret key ของ mongodb
# Applt secret ทุก ENV
kubctl apply -f ../bookinfo-secret/
kubectl get secret --namespace bookinfo-uat
```

* เข้า Browser ด้วย Domain เพื่อ test 


## Production

* Prepare Helm Values for mongodb and ratings
* Change namespace (context) to uat environment
```bash
kubectl config get-contexts
kubectl config set-context $(kubectl config current-context) --namespace=bookinfo-prd
```

* Add configmap and secret
```bash
cd ~/ratings
# Create configmap
kubectl create configmap bookinfo-prd-ratings-mongodb-initdb \
  --from-file=databases/ratings_data.json \
  --from-file=databases/script.sh

# Create Kubernetes Secret via Docker credentials
kubectl create secret generic registry-bookinfo \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson
```

* Helm install mongodb release
```bash
# Deploy new MongoDB with Custom Helm Value of Helm Chart
helm install -f k8s/helm-values/values-bookinfo-prd-ratings-mongodb.yaml \
  bookinfo-prd-ratings-mongodb bitnami/mongodb
```

* Helm install ratings release
```bash
# Deploy Ratings Helm Chart
# Release name = bookinfo-prd-ratings
cd ~/ratings
helm install -f k8s/helm-values/values-bookinfo-prd-ratings.yaml \
  bookinfo-prd-ratings k8s/helm

# Get Status
kubectl get pod,deploy,svc,ingress
```
* เข้า Browser ด้วย Domain เพื่อ test 