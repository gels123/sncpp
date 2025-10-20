use game_data

db.createCollection("account_seq");
db.account_seq.updateOne(
   {"_id": "account_seq"},
   { $setOnInsert: { "nextid": 1000,} },
   { upsert: true }
);


db.createCollection("account");
db.account.createIndex({user: 1}, {unique: true, name: "_index_user_"});


db.createCollection("maildata_seq");
db.maildata_seq.updateOne(
   {"_id": "maildata_seq"},
   { $setOnInsert: { "nextid": 1,} },
   { upsert: true }
);