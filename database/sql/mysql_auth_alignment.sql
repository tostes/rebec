-- Ajustes para alinhar as tabelas auth_* do MySQL legado com o esperado pelo Django 4.2+
-- Execute em um ambiente controlado e após backup completo.
-- Ajuste os nomes de chaves estrangeiras abaixo caso não correspondam aos do seu banco.

SET @OLD_FOREIGN_KEY_CHECKS = @@FOREIGN_KEY_CHECKS;
SET FOREIGN_KEY_CHECKS = 0;

-- auth_user
ALTER TABLE `auth_user`
    MODIFY COLUMN `username` varchar(150) NOT NULL,
    MODIFY COLUMN `first_name` varchar(150) NOT NULL DEFAULT '',
    MODIFY COLUMN `last_name` varchar(150) NOT NULL DEFAULT '',
    MODIFY COLUMN `email` varchar(254) NOT NULL DEFAULT '',
    MODIFY COLUMN `last_login` datetime(6) NULL,
    MODIFY COLUMN `date_joined` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    ENGINE = InnoDB;

-- Remover valores sentinela inválidos em last_login / date_joined
UPDATE `auth_user`
SET `last_login` = NULL
WHERE `last_login` = '0000-00-00 00:00:00';

UPDATE `auth_user`
SET `date_joined` = CURRENT_TIMESTAMP(6)
WHERE `date_joined` = '0000-00-00 00:00:00';

-- auth_group
ALTER TABLE `auth_group`
    MODIFY COLUMN `name` varchar(150) NOT NULL,
    CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    ENGINE = InnoDB;

-- auth_permission
ALTER TABLE `auth_permission`
    MODIFY COLUMN `name` varchar(255) NOT NULL,
    CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    ENGINE = InnoDB;

ALTER TABLE `auth_permission`
    DROP FOREIGN KEY `auth_permission_ibfk_1`;
ALTER TABLE `auth_permission`
    ADD CONSTRAINT `auth_permission_content_type_id_fk`
        FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`)
        ON DELETE CASCADE;

-- auth_group_permissions
ALTER TABLE `auth_group_permissions`
    CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    ENGINE = InnoDB;
ALTER TABLE `auth_group_permissions`
    ADD UNIQUE KEY `auth_group_permissions_group_id_permission_id_uniq` (`group_id`, `permission_id`);
ALTER TABLE `auth_group_permissions`
    DROP FOREIGN KEY `auth_group_permissions_ibfk_1`,
    DROP FOREIGN KEY `auth_group_permissions_ibfk_2`;
ALTER TABLE `auth_group_permissions`
    ADD CONSTRAINT `auth_group_permissions_group_id_fk`
        FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`)
        ON DELETE CASCADE,
    ADD CONSTRAINT `auth_group_permissions_permission_id_fk`
        FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`)
        ON DELETE CASCADE;

-- auth_user_groups
ALTER TABLE `auth_user_groups`
    CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    ENGINE = InnoDB;
ALTER TABLE `auth_user_groups`
    ADD UNIQUE KEY `auth_user_groups_user_id_group_id_uniq` (`user_id`, `group_id`);
ALTER TABLE `auth_user_groups`
    DROP FOREIGN KEY `auth_user_groups_ibfk_1`,
    DROP FOREIGN KEY `auth_user_groups_ibfk_2`;
ALTER TABLE `auth_user_groups`
    ADD CONSTRAINT `auth_user_groups_user_id_fk`
        FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
        ON DELETE CASCADE,
    ADD CONSTRAINT `auth_user_groups_group_id_fk`
        FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`)
        ON DELETE CASCADE;

-- auth_user_user_permissions
ALTER TABLE `auth_user_user_permissions`
    CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    ENGINE = InnoDB;
ALTER TABLE `auth_user_user_permissions`
    ADD UNIQUE KEY `auth_user_user_permissions_user_id_permission_id_uniq` (`user_id`, `permission_id`);
ALTER TABLE `auth_user_user_permissions`
    DROP FOREIGN KEY `auth_user_user_permissions_ibfk_1`,
    DROP FOREIGN KEY `auth_user_user_permissions_ibfk_2`;
ALTER TABLE `auth_user_user_permissions`
    ADD CONSTRAINT `auth_user_user_permissions_user_id_fk`
        FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
        ON DELETE CASCADE,
    ADD CONSTRAINT `auth_user_user_permissions_permission_id_fk`
        FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`)
        ON DELETE CASCADE;

SET FOREIGN_KEY_CHECKS = @OLD_FOREIGN_KEY_CHECKS;
