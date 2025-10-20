/*
 Navicat MySQL Data Transfer

 Source Server         : localhost_root2_1
 Source Server Type    : MySQL
 Source Server Version : 80026
 Source Host           : 192.168.0.106:3306
 Source Schema         : game_data

 Target Server Type    : MySQL
 Target Server Version : 80026
 File Encoding         : 65001

 Date: 05/12/2021 12:43:49
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for account
-- ----------------------------
CREATE TABLE IF NOT EXISTS `account`  (
    `_id` bigint NOT NULL AUTO_INCREMENT,
    `user` varchar(80) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
    `kid` int NOT NULL,
    `status` int NOT NULL,
    `createtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatetime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`_id`) USING BTREE,
    INDEX `key_idx_account_id`(`_id`) USING BTREE,
    INDEX `key_idx_account_user`(`user`) USING BTREE,
    INDEX `key_idx_account_updatetime`(`updatetime`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1000 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '账号信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for lordinfo
-- ----------------------------
CREATE TABLE IF NOT EXISTS `lordinfo`  (
    `_id` bigint NOT NULL,
    `data` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL,
    `createtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatetime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`_id`) USING BTREE,
    INDEX `key_lordinfo_updatetime`(`updatetime`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家领主信息表' ROW_FORMAT = Dynamic;

SET FOREIGN_KEY_CHECKS = 1;

-- ----------------------------
-- Table structure for backpack
-- ----------------------------
CREATE TABLE IF NOT EXISTS `backpack`  (
    `_id` bigint NOT NULL,
    `data` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL,
    `createtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatetime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`_id`) USING BTREE,
    INDEX `key_backpack_updatetime`(`updatetime`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家背包信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for cacheplayer
-- ----------------------------
CREATE TABLE IF NOT EXISTS `cacheplayer`  (
    `_id` bigint NOT NULL,
    `data` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL,
    `createtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatetime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`_id`) USING BTREE,
    INDEX `key_cacheplayer_updatetime`(`updatetime`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家缓存数据表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for setting
-- ----------------------------
CREATE TABLE IF NOT EXISTS `setting`  (
    `_id` bigint NOT NULL,
    `data` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL,
    `createtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatetime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`_id`) USING BTREE,
    INDEX `key_setting_updatetime`(`updatetime`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家设置数据表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for buffinfo
-- ----------------------------
CREATE TABLE IF NOT EXISTS `buffinfo`  (
    `_id` bigint NOT NULL,
    `data` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL,
    `createtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatetime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`_id`) USING BTREE,
    INDEX `key_buffinfo_updatetime`(`updatetime`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家buff数据表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for chatinfo
-- ----------------------------
CREATE TABLE IF NOT EXISTS `chatinfo`  (
    `_id` bigint NOT NULL,
    `data` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL,
    `createtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatetime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`_id`) USING BTREE,
    INDEX `key_chatinfo_updatetime`(`updatetime`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家聊天信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for maildata
-- ----------------------------
CREATE TABLE IF NOT EXISTS `maildata`  (
    `_id` bigint NOT NULL AUTO_INCREMENT,
    `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL,
    `receivers` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL,
    `mailtype` int NULL,
    `settype` int NULL,
    `cfgid` int NULL,
    `expiretime` int NOT NULL,
    `isshared` tinyint NULL,
    `createtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatetime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`_id`) USING BTREE,
    INDEX `key_maildata_cfgid`(`cfgid`) USING BTREE,
    INDEX `key_maildata_expiretime`(`expiretime`) USING BTREE,
    INDEX `key_maildata_updatetime`(`updatetime`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '邮件数据表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for mail
-- ----------------------------
CREATE TABLE IF NOT EXISTS `mail`  (
    `_id` bigint NOT NULL,
    `data` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL,
    `createtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatetime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`_id`) USING BTREE,
    INDEX `key_mail_updatetime`(`updatetime`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家邮件信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for mailshare
-- ----------------------------
CREATE TABLE IF NOT EXISTS `mailshare`  (
    `_id` bigint NOT NULL,
    `data` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL,
    `createtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatetime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`_id`) USING BTREE,
    INDEX `key_mailshare_updatetime`(`updatetime`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '共享邮件信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for mapinfo
-- ----------------------------
CREATE TABLE IF NOT EXISTS `mapinfo`  (
    `_id` bigint NOT NULL,
    `data` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL,
    `createtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatetime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`_id`) USING BTREE,
    INDEX `key_mapinfo_updatetime`(`updatetime`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家地图信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for rpginfo
-- ----------------------------
CREATE TABLE IF NOT EXISTS `rpginfo`  (
    `_id` bigint NOT NULL,
    `data` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL,
    `createtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatetime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`_id`) USING BTREE,
INDEX `key_rpginfo_updatetime`(`updatetime`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家rpg信息表' ROW_FORMAT = Dynamic;
