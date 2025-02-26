// SPDX-License-Identifier: GPL-3.0-or-later

#ifndef _SERVERPLAYER_H
#define _SERVERPLAYER_H

#include "player.h"

class ClientSocket;
class Router;
class Server;
class Room;

class ServerPlayer : public Player {
  Q_OBJECT
public:
  explicit ServerPlayer(Room *room);
  ~ServerPlayer();

  void setSocket(ClientSocket *socket);
  void removeSocket();  // For the running players
  ClientSocket *getSocket() const;

  Server *getServer() const;
  Room *getRoom() const;
  void setRoom(Room *room);

  void speak(const QString &message);

  void doRequest(const QString &command,
           const QString &jsonData, int timeout = -1);
  void abortRequest();
  QString waitForReply(int timeout);
  void doNotify(const QString &command, const QString &jsonData);

  void prepareForRequest(const QString &command,
                        const QString &data);

  volatile bool alive; // For heartbeat
  void kick();

  bool busy() const { return m_busy; }
  void setBusy(bool busy) { m_busy = busy; }
signals:
  void disconnected();
  void kicked();

private:
  ClientSocket *socket;   // socket for communicating with client
  Router *router;
  Server *server;
  Room *room;       // Room that player is in, maybe lobby
  bool m_busy;

  QString requestCommand;
  QString requestData;
};

#endif // _SERVERPLAYER_H
