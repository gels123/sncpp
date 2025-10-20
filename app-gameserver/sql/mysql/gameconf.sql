/*
 Navicat MySQL Data Transfer

 Source Server         : localhost_root2_1
 Source Server Type    : MySQL
 Source Server Version : 80026
 Source Host           : 192.168.0.106:3306
 Source Schema         : game_conf

 Target Server Type    : MySQL
 Target Server Version : 80026
 File Encoding         : 65001
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for conf_cluster
-- ----------------------------
CREATE TABLE IF NOT EXISTS `conf_cluster`  (
  `nodeid` int NOT NULL AUTO_INCREMENT COMMENT '节点ID',
  `nodename` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '节点名',
  `ip` varchar(64) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '专网IP(尽量填固定专网IP, 优先级高于web域名)',
  `web` varchar(64) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '域名',
  `listen` varchar(64) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '监听(填0.0.0.0)',
  `listennodename` varchar(64) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '监听节点名',
  `port` int NOT NULL COMMENT '端口',
  `type` int NOT NULL COMMENT 'cluster节点类型: 1=login 2=global 3=game',
  PRIMARY KEY (`nodeid`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 10002 CHARACTER SET = latin1 COLLATE = latin1_swedish_ci COMMENT = 'cluster集群配置' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of conf_cluster
-- ----------------------------
INSERT INTO `conf_cluster` VALUES (1, 'my_node_game_1', '127.0.0.1', '127.0.0.1', '0.0.0.0', 'listen_my_node_game_1', 2001, 3);
INSERT INTO `conf_cluster` VALUES (10001, 'my_node_login', '127.0.0.1', '127.0.0.1', '0.0.0.0', 'listen_my_node_login', 2801, 1);
INSERT INTO `conf_cluster` VALUES (10002, 'my_node_global', '127.0.0.1', '127.0.0.1', '0.0.0.0', 'listen_my_node_global', 2802, 2);

-- ----------------------------
-- Table structure for conf_debug
-- ----------------------------
CREATE TABLE IF NOT EXISTS `conf_debug`  (
  `nodeid` int NOT NULL COMMENT '节点ID',
  `ip` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT 'IP地址',
  `web` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '域名',
  `port` int NOT NULL COMMENT '端口',
  PRIMARY KEY (`nodeid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = latin1 COLLATE = latin1_swedish_ci COMMENT = '控制台配置' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of conf_debug
-- ----------------------------
INSERT INTO `conf_debug` VALUES (1, '127.0.0.1', '127.0.0.1', 3001);
INSERT INTO `conf_debug` VALUES (10001, '127.0.0.1', '127.0.0.1', 3801);
INSERT INTO `conf_debug` VALUES (10002, '127.0.0.1', '127.0.0.1', 3802);

-- ----------------------------
-- Table structure for conf_gate
-- ----------------------------
CREATE TABLE IF NOT EXISTS `conf_gate`  (
  `nodeid` int NOT NULL DEFAULT 0 COMMENT '节点ID',
  `web` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '域名',
  `address` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '专网IP(尽量填固定专网IP, 优先级高于web域名)',
  `proxy` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理',
  `listen` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '监听(填0.0.0.0)',
  `port` int NOT NULL COMMENT '端口',
  PRIMARY KEY (`nodeid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of conf_gate
-- ----------------------------
INSERT INTO `conf_gate` VALUES (1, '127.0.0.1', '127.0.0.1', '127.0.0.1', '0.0.0.0', 4001);
INSERT INTO `conf_gate` VALUES (10002, '127.0.0.1', '127.0.0.1', '127.0.0.1', '0.0.0.0', 4802);

-- ----------------------------
-- Table structure for conf_gatepvp
-- ----------------------------
CREATE TABLE IF NOT EXISTS `conf_gatepvp`  (
  `nodeid` int NOT NULL DEFAULT 0 COMMENT '节点ID',
  `web` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '域名',
  `address` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT 'IP地址',
  `proxy` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理',
  `listen` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '监听(填0.0.0.0)',
  `port` int NOT NULL COMMENT '端口',
  PRIMARY KEY (`nodeid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of conf_gatepvp
-- ----------------------------
INSERT INTO `conf_gatepvp` VALUES (1, '127.0.0.1', '127.0.0.1', '127.0.0.1', '0.0.0.0', 4803);

-- ----------------------------
-- Table structure for conf_general
-- ----------------------------
CREATE TABLE IF NOT EXISTS `conf_general`  (
  `ID` int NOT NULL AUTO_INCREMENT,
  `verifyhost` varchar(500) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '充值验证主机名',
  `verifyiosurl` varchar(500) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '苹果充值验证地址',
  `verifyandroidurl` varchar(500) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '谷歌play充值验证地址',
  `clientMinVer` varchar(500) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL COMMENT '客户端最小版本号',
  `defaultKid` int NOT NULL DEFAULT 1 COMMENT '新注册账号默认分配的王国ID',
  `distributor` int NULL DEFAULT 1,
  `defaultKids` varchar(500) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL,
  `verifyiossuburl` varchar(500) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT 'url',
  PRIMARY KEY (`ID`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = latin1 COLLATE = latin1_swedish_ci COMMENT = '通用配置' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of conf_general
-- ----------------------------
INSERT INTO `conf_general` VALUES (1, '127.0.0.1', '/recharge/rok/game-recharge/verifyIAPReceipt.php', '/recharge/rok/game-recharge/androidVerify.php', '0.00.001', 1, 1, NULL, '/recharge/rok/game-recharge/verifyIAPSubscriptionReceipt.php');

-- ----------------------------
-- Table structure for conf_http
-- ----------------------------
CREATE TABLE IF NOT EXISTS `conf_http`  (
  `nodeid` int NOT NULL COMMENT '节点ID',
  `host` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '专网IP(尽量填固定专网IP, 优先级高于web域名)',
  `web` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '' COMMENT '域名',
  `listen` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '监听(填0.0.0.0)',
  `port` int NOT NULL COMMENT '端口',
  `instance` int NOT NULL COMMENT '实例数',
  `limitbody` int NOT NULL,
  PRIMARY KEY (`nodeid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = latin1 COLLATE = latin1_swedish_ci COMMENT = 'web服务配置' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of conf_http
-- ----------------------------
INSERT INTO `conf_http` VALUES (10001, '127.0.0.1', '127.0.0.1', '0.0.0.0', 5001, 10, 81920);

-- ----------------------------
-- Table structure for conf_ipwhitelist
-- ----------------------------
CREATE TABLE IF NOT EXISTS `conf_ipwhitelist`  (
  `nodeid` int NOT NULL COMMENT '节点id',
  `ipList` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '白名单列表(ip;ip;)',
  `status` int NOT NULL COMMENT '开关(0关,1开)',
  PRIMARY KEY (`nodeid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = latin1 COLLATE = latin1_swedish_ci COMMENT = 'ip白名单列表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of conf_ipwhitelist
-- ----------------------------
INSERT INTO `conf_ipwhitelist` VALUES (1, '127.0.0.1;', 1);

-- ----------------------------
-- Table structure for conf_kingdom
-- ----------------------------
CREATE TABLE IF NOT EXISTS `conf_kingdom`  (
  `kid` int NOT NULL COMMENT '王国ID',
  `nodeid` int NOT NULL COMMENT '王国所属节点ID',
  `status` int NOT NULL DEFAULT 0,
  `startTime` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '开服日期',
  `isNew` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`kid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = latin1 COLLATE = latin1_swedish_ci COMMENT = '王国配置表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of conf_kingdom
-- ----------------------------
INSERT INTO `conf_kingdom` VALUES (1, 1, 0, '2023-01-01 00:00:00', 1);

-- ----------------------------
-- Table structure for conf_login
-- ----------------------------
CREATE TABLE IF NOT EXISTS `conf_login`  (
  `nodeid` int NOT NULL COMMENT '节点ID',
  `host` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '专网IP(尽量填固定专网IP, 优先级高于web域名)',
  `web` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '域名',
  `listen` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT '监听(填0.0.0.0)',
  `port` int NOT NULL COMMENT '端口',
  `instance` int NOT NULL COMMENT 'slave service count',
  `mastername` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '' COMMENT 'master服务名称',
  `limitbody` int NOT NULL COMMENT 'upload max bytes',
  PRIMARY KEY (`nodeid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = latin1 COLLATE = latin1_swedish_ci COMMENT = '登录服务配置表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of conf_login
-- ----------------------------
INSERT INTO `conf_login` VALUES (10001, '127.0.0.1', '127.0.0.1', '0.0.0.0', 6001, 16, '.loginMaster', 8192);

-- ----------------------------
-- Table structure for conf_noticehttp
-- ----------------------------
CREATE TABLE IF NOT EXISTS `conf_noticehttp`  (
  `id` int NOT NULL DEFAULT 0,
  `host` varchar(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `url` varchar(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of conf_noticehttp
-- ----------------------------
INSERT INTO `conf_noticehttp` VALUES (1, '127.0.0.1', '/pushserver/message/push');

SET FOREIGN_KEY_CHECKS = 1;
