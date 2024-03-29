#
# * Copyright (c) Novedia Group 2012.
# *
# *    This file is part of Hubiquitus
# *
# *    Permission is hereby granted, free of charge, to any person obtaining a copy
# *    of this software and associated documentation files (the "Software"), to deal
# *    in the Software without restriction, including without limitation the rights
# *    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# *    of the Software, and to permit persons to whom the Software is furnished to do so,
# *    subject to the following conditions:
# *
# *    The above copyright notice and this permission notice shall be included in all copies
# *    or substantial portions of the Software.
# *
# *    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# *    INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# *    PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# *    FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# *    ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# *
# *    You should have received a copy of the MIT License along with Hubiquitus.
# *    If not, see <http://opensource.org/licenses/mit-license.php>.
#

async = require 'async'
validator = require "../validator"
Adapter = require "./Adapter"
UUID = require "../UUID"

#
# Class that defines an Inbound adapter
#
class InboundAdapter extends Adapter

  # @property {function} onMessage
  onMessage: undefined

  #
  # Adapter's constructor
  # @param properties {object} Launch properties of the adapter
  #
  constructor: (properties) ->
    @direction = "in"
    super

    args = [];
    if @authenticator then args.push @authenticator.authorize
    if @serializer then args.push @serializer.decode
    if @makeHMessage then args.push @makeHMessage
    args.push @h_fillMessage
    args.push validator.validateHMessage
    @filters.forEach (filter) ->
      args.push filter.validate

    @onMessage = async.compose.apply null, args.reverse()

  #
  # @private
  #
  h_fillMessage: (hMessage, callback) ->
    unless hMessage.sent
      hMessage.sent = new Date().getTime()
    unless hMessage.msgid
      hMessage.msgid = UUID.generate()
    callback null, hMessage


  #
  # Make an hMessage from decoded data and provided metadata
  # @param data {object, string, number, boolean} decoded data given by the adapter
  # @param metadata {object} data metadata provided by the adapter
  # @params callback {function} called once lock is acquire or an error occured
  # @options callback err {object, string} only defined if an error occcured
  # @options callback hMessage {object} Hmessage created from given data
  #
  makeHMessage: (data, metadata, callback) ->
    callback null, data

  #
  # @param buffer {buffer}
  #
  receive: (buffer, metadata) =>
    @onMessage buffer, metadata, (err, hMessage) =>
      if err
        @owner.log "error", if typeof err is 'string' then err else JSON.stringify(err)
      else
        @owner.emit 'message', hMessage


module.exports = InboundAdapter
