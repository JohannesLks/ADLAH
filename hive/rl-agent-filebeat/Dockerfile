# SPDX-License-Identifier: GPL-3.0-or-later
# ADLAH - Adaptive Deep Learning Anomaly Detection Honeynet <https://github.com/JohannesLks/ADLAH/>
# Copyright (C) 2025  Lukas Johannes Möller
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
FROM docker.elastic.co/beats/filebeat:8.6.0

USER root
WORKDIR /usr/share/filebeat

COPY filebeat.yml ./filebeat.yml
RUN chown root:root /usr/share/filebeat/filebeat.yml \
 && chmod 0644   /usr/share/filebeat/filebeat.yml

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN mkdir -p /usr/share/filebeat/certs \
 && chown filebeat:filebeat /usr/share/filebeat/certs

USER filebeat

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
