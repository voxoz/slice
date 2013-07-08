FROM voxoz/precise
RUN sed -i '1d' /etc/shadow
RUN echo 'root:{{password}}:15881:0:99999:7:::' >> /etc/shadow
EXPOSE 22
CMD ["/usr/bin/supervisord", "-n"]
