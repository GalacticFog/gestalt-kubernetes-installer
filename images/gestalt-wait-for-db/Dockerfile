FROM postgres:9.6.11

COPY ./wait_for_db.sh /usr/local/bin/wait_for_db.sh
RUN chmod +x /usr/local/bin/wait_for_db.sh
# CMD ["/bin/bash", "-c", "/usr/local/bin/wait_for_db.sh"]
ENTRYPOINT [ "/bin/bash", "-c", "/usr/local/bin/wait_for_db.sh" ]
