#! /bin/sh

# # FIRST: give root access to the mcp program, "nice" , and this shell script
# sudo chown root:root /home/lawson/NestRead/mcp_read_pigpio
# sudo chmod 4755 /home/lawson/NestRead/mcp_read_pigpio
# sudo chown root:root /usr/bin/nice
# sudo chmod 4755 /usr/bin/nice
# sudo chown root:root /home/lawson/NestRead/temp_read_v02.py
# sudo chmod 4755 /home/lawson/NestRead/temp_read_v02.py
# sudo chown root:root /home/lawson/NestRead/NestRead.sh
# sudo chmod 4755 /home/lawson/NestRead/NestRead.sh


# Run program via screen and automatically detach
screen -dm nice -n -19 python /home/lawson/NestRead/temp_read_v02.py
screen -dm nice -n -20 /home/lawson/NestRead/mcp_read_pigpio