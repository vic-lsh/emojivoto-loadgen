#/bin/sh

kubectl apply -f /scratch/shli/emojivoto/training/service-profiles/voting-svc-profile.yml
kubectl apply -f /scratch/shli/emojivoto/training/service-profiles/emoji-svc-profile.yml
kubectl apply -f /scratch/shli/emojivoto/training/service-profiles/web-service-profile-with-timeout.yml
kubectl apply -f /scratch/shli/emojivoto/training/service-profiles/web-service-profile-with-retry-budget.yml

