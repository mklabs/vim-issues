

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
  this.request('repos/:repo/issues', this.opts).pipe(process.stdout);
};

Issues.prototype.comments = function() {
  if(!this.opts.repo) return this.emit('error', new Error('repo options is undefined'));
  if(!this.opts.id) return this.emit('error', new Error('id option is undefined'));

  var req = this.request('repos/:repo/issues/:id/comments', this.opts);
  var body = '';
  req
    .on('data', function(chunk) { body += chunk; })
    .on('end', function() {
      var comments = JSON.parse(body);

      comments.forEach(function(c) {
        var title = '¶ ' + c.user.login + ' commented';
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
  var url = 'https://api.github.com/' + pathname;
  // https://api.github.com/repos/yeoman/generators/issues
  Object.keys(data).forEach(function(key) {
    url = url.replace(':' + key, data[key]);
  });
  return request({ url: url, json: true, headers: { 'User-Agent': 'vim-issues' }});
};

