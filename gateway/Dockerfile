FROM nginx:alpine

ARG ENV=dev

RUN rm etc/nginx/conf.d/default.conf

COPY nginx.${ENV}.conf /etc/nginx/conf.d/default.conf