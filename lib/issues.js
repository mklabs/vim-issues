

// Module dependencies

var fs = require('fs'),
  path = require('path'),
  util = require('util'),
  events = require('events'),
  request = require('request');

module.exports = Issues;

// 101 mapping with autoloaded issues#issues() object

function Issues(opts) {
  events.EventEmitter.call(this);
  this.opts = opts || {};
  this.on('list', this.list);
  this.on('request', this.request);
  this.on('comments', this.comments);
}

util.inherits(Issues, events.EventEmitter);

Issues.prototype.list = function() {
  if(!this.opts.repo) return this.emit('error', new Error('repo options is undefined'));
  this.request('issues/list/:repo/open', this.opts).pipe(process.stdout);
};

Issues.prototype.comments = function() {
  if(!this.opts.repo) return this.emit('error', new Error('repo options is undefined'));
  if(!this.opts.id) return this.emit('error', new Error('id option is undefined'));

  var req = this.request('issues/comments/:repo/:id', this.opts);
  var body = '';
  req
    .on('data', function(chunk) { body += chunk; })
    .on('end', function() {
      var data = JSON.parse(body);

      data.comments.forEach(function(c) {
        var title = '¶ ' + c.user + ' commented';
        console.log(title);
        console.log(new Array(title.length).join('-'));
        console.log();
        console.log(' - ' + c.created_at);
        console.log('');
        console.log(c.body.replace(/\r/g, ''));
        console.log();
        console.log();
      });
    });
};

Issues.prototype.request = function(pathname, data) {
  var url = 'http://github.com/api/v2/json/' + pathname;
  Object.keys(data).forEach(function(key) {
    url = url.replace(':' + key, data[key]);
  });
  return request(url);
};

